from resono.phase_embed import encode
from resono.phase_extract import decode
import argparse

def main():
    parser = argparse.ArgumentParser(description='Audio steganography tool on phase coding method')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # Embed command
    embed = subparsers.add_parser('embed', help='Hide text in an audio')
    embed.add_argument('--in', dest='payload', required=True, help='write the text to hide')
    embed.add_argument('--cover', dest='audio', required=True, help='Cover audio')
    embed.add_argument('--key', required=True, help='A secret key to lock your data')
    
    # Extract command
    extract = subparsers.add_parser('extract', help='Extract the hidden payload')
    extract.add_argument('--stego', required=True, help='Audio with hidden text')
    extract.add_argument('--key', required=True, help='A secret key to unlock the data')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        exit(1)

    try:
        if args.command == 'embed':
            encode(args.audio, args.payload, args.key)
            print("Successfully embedded the payload in encoded.wav file")
        elif args.command == 'extract':
            decode(args.stego, args.key)
            print("Successfully extracted the payload!")
    except Exception as e:
        print(f"Error: {e}")
        exit(1)

if __name__ == '__main__':
    main()