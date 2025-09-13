import numpy as np
from scipy.io import wavfile
import random
from resono.aes import *
import binascii
import struct

def final_payload(epayload):
    length = len(epayload)
    if length > 0xFFFF: # 0xFFFF is 65,355 in decimal which is 65kb
        raise ValueError("The length is big to fit the 2byte length prefix!!")
    length_prefix = struct.pack(">H", length) #it takes big endian with H (unsigned 16bits) and length of the epayload (138)
    checksum = binascii.crc32(epayload) & 0xFFFFFFFF
    checksum_prefix = struct.pack(">I", checksum) #it takes big endian with I (unsigned 32 bits) so the data will have exactly 4bytes of data and checksum
    final = length_prefix + checksum_prefix + epayload
    return final

def encode(audio, payload, key):
    rate,audio = wavfile.read(audio)

    if audio.dtype != np.int16:
        if audio.dtype == np.float32 or audio.dtype == np.float64:
            if np.max(np.abs(audio)) <= 1.0:
                audio = (audio * 32767).astype(np.int16)
            else:
                audio = np.clip(audio, -32768, 32767).astype(np.int16)
            print("Converted audio format to int16")
        elif audio.dtype == np.int32:
            audio = (audio//65536).astype(np.int16)
            print("Converted audio format to int16")

    if np.all(audio == 0):
        raise ValueError("Input audio file appears to be silent or corrupted!!")
    
    payload = payload.ljust(100).encode('utf-8')
    if len(payload) > 100:
        raise ValueError("The limit exceeds 100 characters")
    
    epayload = encryption(payload, key)
    finalp = final_payload(epayload)
    textInBinary = np.unpackbits(np.frombuffer(finalp,dtype=np.uint8))
    total_bits = len(textInBinary)

    blockLength = int(2 * 2 ** np.ceil(np.log2(2 * total_bits)))

    caudio = audio.copy()        
    # checks shape to change data to 1 axis
    if len(audio.shape) == 1:
        samples = len(audio)
        mono = True
        audio_channel = caudio.copy()
        print("Detected mono audio. Processing...")
    elif len(audio.shape) == 2:     
        samples = audio.shape[0]
        mono = False
        right_channel = audio[:,1].copy()
        left_channel = audio[:, 0].copy()
        print("Detected stereo audio. Selecting channel...")

        if np.sum(np.abs(left_channel)) >= np.sum(np.abs(right_channel)):
            audio_channel = left_channel
            org_right = right_channel
            print("Using left channel to embed!")
        else:
            audio_channel = right_channel
            org_right = left_channel
            print("Using right channel to embed!")
        
    else:
        raise NotImplementedError("Only mono or stereo channels are allowed!!")

    blockNumber = int(np.ceil(samples / blockLength))

    B = 8
    capacity = blockNumber * B
    if total_bits > capacity:
        raise ValueError(f"Audio too short! Need {total_bits} bits, capacity is {capacity}")
    
    print(f"Embedding message in audio...")
    print(f"Audio capacity: {capacity} bits, using {total_bits} bits")
    
    required_samples = blockNumber * blockLength

    if len(audio_channel) < required_samples:
        audio_channel = np.pad(audio_channel, (0, required_samples - len(audio_channel)), mode='constant')
    else:
        audio_channel = audio_channel[:required_samples]

    blocks = audio_channel.reshape((blockNumber, blockLength))
    
    dft = np.fft.fft(blocks, axis=1)  # Calculate DFT using fft  
    magnitudes = np.abs(dft) # calculate magnitudes   
    phases = np.angle(dft) # create phase matrix   

    blockMid = blockLength // 2
    candidates = list(range(1, blockMid))
    seed = to_seed(key)
    magic = random.Random(seed)
    magic.shuffle(candidates)

    print("Modifying phases...")
    bit_idx = 0

    for block_idx in range(blockNumber):
        if bit_idx >= total_bits:
            break

        bins = candidates[block_idx*B : (block_idx+1)*B]
        for b in bins:
            if bit_idx >= total_bits:
                break

            bit = textInBinary[bit_idx]
            omega = (+np.pi/2) if bit else (-np.pi/2)
            phases[block_idx, b] = omega
            phases[block_idx, blockLength - b] = -omega #Mirror frequency
            bit_idx += 1

        if bit_idx >= total_bits:
            break

    modified_fft = magnitudes * np.exp(1j * phases)
    renew_block = np.fft.ifft(modified_fft, axis=1)
    renew_block = np.real(renew_block)
    renew_block = np.clip(renew_block, -32768, 32767)

    new_audio = renew_block.ravel().astype(np.int16)

    if mono:
        output = new_audio
    else:
        min_length = min(len(new_audio), len(org_right))
        output = np.zeros((min_length, 2), dtype=np.int16)
        output[:, 0] = new_audio[:min_length]
        output[:,1] = org_right[:min_length]

    wavfile.write("encoded.wav", rate, output)
    print("Output saved as: encoded.wav")
    return "encoded.wav"