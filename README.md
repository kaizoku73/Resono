# Resono 🎵🔒

A sophisticated audio steganography tool that uses phase coding techniques to hide encrypted text messages within audio files. Resono combines cryptographic security with advanced signal processing to provide a robust solution for covert communication.

## 🌟 Features

- **Phase-based Steganography**: Utilizes phase manipulation in the frequency domain to embed data imperceptibly
- **AES Encryption**: All hidden messages are encrypted using AES-256 in EAX mode before embedding
- **Key-based Security**: Uses password-derived keys for both encryption and pseudorandom frequency bin selection
- **Audio Format Support**: Works with WAV files (mono and stereo)
- **Data Integrity**: Includes CRC32 checksums to detect corruption or tampering
- **Flexible Capacity**: Automatically calculates embedding capacity based on audio length
- **Robust Error Handling**: Comprehensive validation and error reporting

## 🔧 Quick Start

### Prerequisites
- Python 3.6+
- Required packages:

```bash
pip install numpy scipy pycryptodome
```

### Installation

```bash
pip install resono
```

### One-Line Installation

```bash
# System-wide (with sudo)
curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/install.sh | sudo bash

# User installation (no sudo)
curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/install.sh | bash
```
### Uninstallation

```bash
# To uninstall Resono (no sudo):
curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/uninstall.sh | bash

# To uninstall Resono (With sudo):
curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/uninstall.sh | sudo bash

```

### Clone the Repository
```bash
git clone https://github.com/kaizoku73/Resono.git
cd Resono
```

## 🚀 Usage

Resono provides a simple command-line interface for both embedding and extracting hidden messages.

### Embedding a Message

```bash
resono embed --in "Your secret message here" --cover input_audio.wav --key "your_secret_password"
```

**Parameters:**
- `--in`: The text message to hide (max 100 characters)
- `--cover`: Path to the cover audio file (WAV format)
- `--key`: Secret password for encryption and embedding

**Output:** Creates `encoded.wav` with the hidden message

### Extracting a Message

```bash
resono extract --stego encoded.wav --key "your_secret_password"
```

**Parameters:**
- `--stego`: Path to the audio file containing the hidden message
- `--key`: The same secret password used for embedding

## 🔬 How It Works

### 1. **Message Preparation**
- Input text is padded to 100 characters using white spaces
- Message is encrypted using AES-256 in EAX mode
- Length prefix and CRC32 checksum are added for integrity

### 2. **Phase Encoding**
- Audio is processed in blocks using FFT (Fast Fourier Transform)
- Frequency bins are selected pseudorandomly based on the key
- Phase values are modified: +π/2 for bit '1', -π/2 for bit '0'
- Mirror frequencies are adjusted to maintain audio quality

### 3. **Audio Reconstruction**
- Modified frequency domain data is converted back using IFFT
- Resulting audio maintains original characteristics while containing hidden data

### 4. **Extraction Process**
- Reverse FFT analysis extracts phase information
- Same pseudorandom sequence recovers embedded bits
- Decryption and integrity verification reveal the original message

## What is Phase coding and how does it work?
For a detailed explanation of Phase coding steganography and how it works, check out this article: https://kaizoku.gitbook.io/steganography/phase-coding-in-audio

## 📊 Technical Specifications

- **Encryption**: AES-256 in EAX mode
- **Hash Function**: SHA-256 for key derivation
- **Block Processing**: Dynamic block sizing based on message length
- **Capacity**: 8 bits per audio block
- **Audio Formats**: 16-bit WAV files (mono/stereo)
- **Message Limit**: 100 characters maximum
- **Integrity Check**: CRC32 checksums

## 🎯 Advantages

- **Imperceptible**: Phase changes are inaudible to human ears
- **Secure**: Military-grade AES encryption protects message content
- **Robust**: Error detection and correction mechanisms
- **Flexible**: Works with various audio lengths and formats
- **Pseudorandom**: Key-based frequency selection prevents pattern detection

## ⚠️ Limitations

- Maximum message length: 100 characters
- Requires sufficient audio length for embedding capacity
- WAV format only (currently)
- Both embedding and extraction require the same secret key

## 🔐 Security Considerations

- Use strong, unique passwords for each hidden message
- The security relies on keeping the password secret
- Audio files may be subject to compression or conversion attacks
- Consider additional obfuscation techniques for highly sensitive data

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## ⚖️ Disclaimer

This tool is for educational and research purposes. Users are responsible for complying with all applicable laws and regulations regarding encryption and steganography in their jurisdiction.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.

---

**Resono** - Where secrets hide in plain sound 🎵
---

**Made by Kaizoku**
