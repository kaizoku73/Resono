import numpy as np
from resono.aes import *
from scipy.io import wavfile
import random
import struct
import binascii

def decode(audio, key):
    rate, audio = wavfile.read(audio)

    if audio.ndim == 1:
        mono = True
        audio_channel = audio
        audio_samples = len(audio)
        print("Detected mono audio. Processing...")
    elif audio.ndim == 2:
        mono = False
        audio_samples = len(audio)
        left_channel = audio[:,0].copy()
        right_channel = audio[:,1].copy()
        print("Detected stereo audio. Selecting channel...")

        if np.sum(np.abs(left_channel)) >= np.sum(np.abs(right_channel)):
            audio_channel = left_channel
            print("Using left channel to extract!")
        else:
            audio_channel = right_channel
            print("Using right channel to extract!")

    else:
        raise NotImplementedError("Only mono or stereo channels are allowed!!")
    
    total_bits = 138 * 8

    blockLength = int(2 * 2 ** np.ceil(np.log2(2 * total_bits)))
    blockNum = int(np.ceil(audio_samples / blockLength))

    B = 8
    capacity = blockNum * B

    if total_bits > capacity:
        raise ValueError(f"Audio is too short! Need {total_bits} bits, can extract {capacity} bits.")

    required = blockNum * blockLength
    if len(audio_channel) < required:
        padding = required - len(audio_channel)
        audio_channel = np.pad(audio_channel, (0, padding), mode='constant')
    else:
        audio_channel = audio_channel[:required]


    blocks = audio_channel.reshape((blockNum, blockLength))
    dft = np.fft.fft(blocks, axis=1)
    phases = np.angle(dft)


    blockMid = blockLength // 2
    candidates = list(range(1, blockMid))
    magic = random.Random(to_seed(key))
    magic.shuffle(candidates)

    print("Extracting message from audio...")

    extracted_bits = []
    bit_idx = 0

    for block_idx in range(blockNum):
        if bit_idx >= total_bits:
            break
        bins = candidates[block_idx*B : (block_idx+1) * B]
        for b in bins:
            if bit_idx >= total_bits:
                break
            phase_val = phases[block_idx, b]
            bit = 1 if phase_val > 0 else 0
            extracted_bits.append(bit)
            bit_idx += 1
    
    if len(extracted_bits) < total_bits:
        raise ValueError("Not enough bits extracted") 

    extracted_bytes = np.packbits(np.array(extracted_bits[:total_bits], dtype=np.uint8), bitorder='big').tobytes()
    if len(extracted_bytes) < 6:
        print("Insufficient data extracted - audio may not contain a message.")
        return None
    
    length = struct.unpack(">H", extracted_bytes[:2])[0]
    crc = struct.unpack(">I", extracted_bytes[2:6])[0]
    epayload = extracted_bytes[6:6+length]

    ocrc = binascii.crc32(epayload) & 0xFFFFFFFF
    if ocrc != crc:
        print("Data integrity check failed - file may be corrupted")
        raise ValueError("Crc mismatch - data corrupted")
        
    text = decryption(epayload, key)
    recover = text.rstrip().decode("utf-8")
    print("Message extracted successfully!!")
    print(f"Extracted message : {recover}")
    return recover   