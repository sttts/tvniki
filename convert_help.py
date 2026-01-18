#!/usr/bin/env python3
"""Convert hilfe.hlp from CP437 to UTF-8 encoding."""

import struct
import sys

# CP437 to Unicode mapping for bytes 128-255
CP437_MAP = {
    0x80: '\u00C7',  # Ç
    0x81: '\u00FC',  # ü
    0x82: '\u00E9',  # é
    0x83: '\u00E2',  # â
    0x84: '\u00E4',  # ä
    0x85: '\u00E0',  # à
    0x86: '\u00E5',  # å
    0x87: '\u00E7',  # ç
    0x88: '\u00EA',  # ê
    0x89: '\u00EB',  # ë
    0x8A: '\u00E8',  # è
    0x8B: '\u00EF',  # ï
    0x8C: '\u00EE',  # î
    0x8D: '\u00EC',  # ì
    0x8E: '\u00C4',  # Ä
    0x8F: '\u00C5',  # Å
    0x90: '\u00C9',  # É
    0x91: '\u00E6',  # æ
    0x92: '\u00C6',  # Æ
    0x93: '\u00F4',  # ô
    0x94: '\u00F6',  # ö
    0x95: '\u00F2',  # ò
    0x96: '\u00FB',  # û
    0x97: '\u00F9',  # ù
    0x98: '\u00FF',  # ÿ
    0x99: '\u00D6',  # Ö
    0x9A: '\u00DC',  # Ü
    0x9B: '\u00A2',  # ¢
    0x9C: '\u00A3',  # £
    0x9D: '\u00A5',  # ¥
    0x9E: '\u20A7',  # ₧
    0x9F: '\u0192',  # ƒ
    0xA0: '\u00E1',  # á
    0xA1: '\u00ED',  # í
    0xA2: '\u00F3',  # ó
    0xA3: '\u00FA',  # ú
    0xA4: '\u00F1',  # ñ
    0xA5: '\u00D1',  # Ñ
    0xA6: '\u00AA',  # ª
    0xA7: '\u00BA',  # º
    0xA8: '\u00BF',  # ¿
    0xA9: '\u2310',  # ⌐
    0xAA: '\u00AC',  # ¬
    0xAB: '\u00BD',  # ½
    0xAC: '\u00BC',  # ¼
    0xAD: '\u00A1',  # ¡
    0xAE: '\u00AB',  # «
    0xAF: '\u00BB',  # »
    0xB0: '\u2591',  # ░
    0xB1: '\u2592',  # ▒
    0xB2: '\u2593',  # ▓
    0xB3: '\u2502',  # │
    0xB4: '\u2524',  # ┤
    0xB5: '\u2561',  # ╡
    0xB6: '\u2562',  # ╢
    0xB7: '\u2556',  # ╖
    0xB8: '\u2555',  # ╕
    0xB9: '\u2563',  # ╣
    0xBA: '\u2551',  # ║
    0xBB: '\u2557',  # ╗
    0xBC: '\u255D',  # ╝
    0xBD: '\u255C',  # ╜
    0xBE: '\u255B',  # ╛
    0xBF: '\u2510',  # ┐
    0xC0: '\u2514',  # └
    0xC1: '\u2534',  # ┴
    0xC2: '\u252C',  # ┬
    0xC3: '\u251C',  # ├
    0xC4: '\u2500',  # ─
    0xC5: '\u253C',  # ┼
    0xC6: '\u255E',  # ╞
    0xC7: '\u255F',  # ╟
    0xC8: '\u255A',  # ╚
    0xC9: '\u2554',  # ╔
    0xCA: '\u2569',  # ╩
    0xCB: '\u2566',  # ╦
    0xCC: '\u2560',  # ╠
    0xCD: '\u2550',  # ═
    0xCE: '\u256C',  # ╬
    0xCF: '\u2567',  # ╧
    0xD0: '\u2568',  # ╨
    0xD1: '\u2564',  # ╤
    0xD2: '\u2565',  # ╥
    0xD3: '\u2559',  # ╙
    0xD4: '\u2558',  # ╘
    0xD5: '\u2552',  # ╒
    0xD6: '\u2553',  # ╓
    0xD7: '\u256B',  # ╫
    0xD8: '\u256A',  # ╪
    0xD9: '\u2518',  # ┘
    0xDA: '\u250C',  # ┌
    0xDB: '\u2588',  # █
    0xDC: '\u2584',  # ▄
    0xDD: '\u258C',  # ▌
    0xDE: '\u2590',  # ▐
    0xDF: '\u2580',  # ▀
    0xE0: '\u03B1',  # α
    0xE1: '\u00DF',  # ß
    0xE2: '\u0393',  # Γ
    0xE3: '\u03C0',  # π
    0xE4: '\u03A3',  # Σ
    0xE5: '\u03C3',  # σ
    0xE6: '\u00B5',  # µ
    0xE7: '\u03C4',  # τ
    0xE8: '\u03A6',  # Φ
    0xE9: '\u0398',  # Θ
    0xEA: '\u03A9',  # Ω
    0xEB: '\u03B4',  # δ
    0xEC: '\u221E',  # ∞
    0xED: '\u03C6',  # φ
    0xEE: '\u03B5',  # ε
    0xEF: '\u2229',  # ∩
    0xF0: '\u2261',  # ≡
    0xF1: '\u00B1',  # ±
    0xF2: '\u2265',  # ≥
    0xF3: '\u2264',  # ≤
    0xF4: '\u2320',  # ⌠
    0xF5: '\u2321',  # ⌡
    0xF6: '\u00F7',  # ÷
    0xF7: '\u2248',  # ≈
    0xF8: '\u00B0',  # °
    0xF9: '\u2219',  # ∙
    0xFA: '\u00B7',  # ·
    0xFB: '\u221A',  # √
    0xFC: '\u207F',  # ⁿ
    0xFD: '\u00B2',  # ²
    0xFE: '\u25A0',  # ■
    0xFF: '\u00A0',  # NBSP (used as space in help file)
}

# Low ASCII control characters that have graphical representations in CP437
CP437_LOW = {
    0x01: '\u263A',  # ☺
    0x02: '\u263B',  # ☻
    0x03: '\u2665',  # ♥
    0x04: '\u2666',  # ♦
    0x05: '\u2663',  # ♣
    0x06: '\u2660',  # ♠
    0x07: '\u2022',  # •
    0x08: '\u25D8',  # ◘
    0x09: '\u25CB',  # ○
    0x0A: '\u25D9',  # ◙
    0x0B: '\u2642',  # ♂
    0x0C: '\u2640',  # ♀
    0x0D: '\r',      # Keep CR as-is (line ending)
    0x0E: '\u266B',  # ♫
    0x0F: '\u263C',  # ☼
    0x10: '\u25BA',  # ►
    0x11: '\u25C4',  # ◄
    0x12: '\u2195',  # ↕
    0x13: '\u203C',  # ‼
    0x14: '\u00B6',  # ¶
    0x15: '\u00A7',  # §
    0x16: '\u25AC',  # ▬
    0x17: '\u21A8',  # ↨
    0x18: '\u2191',  # ↑
    0x19: '\u2193',  # ↓
    0x1A: '\u2192',  # →
    0x1B: '\u2190',  # ←
    0x1C: '\u221F',  # ∟
    0x1D: '\u2194',  # ↔
    0x1E: '\u25B2',  # ▲
    0x1F: '\u25BC',  # ▼
}


def cp437_byte_to_utf8(b):
    """Convert a single CP437 byte to UTF-8 string."""
    if b < 0x20:
        return CP437_LOW.get(b, chr(b))
    elif b < 0x80:
        return chr(b)
    else:
        return CP437_MAP.get(b, '?')


def convert_text(data):
    """Convert CP437 bytes to UTF-8 string."""
    return ''.join(cp437_byte_to_utf8(b) for b in data)


def build_byte_offset_map(data):
    """Build a mapping from CP437 byte offsets to UTF-8 byte offsets.

    Returns a list where map[cp437_offset] = utf8_offset.
    The list has len(data)+1 entries to handle end-of-string offsets.
    """
    offset_map = []
    utf8_pos = 0
    for b in data:
        offset_map.append(utf8_pos)
        utf8_char = cp437_byte_to_utf8(b)
        utf8_pos += len(utf8_char.encode('utf-8'))
    offset_map.append(utf8_pos)  # End position
    return offset_map


def read_word(f):
    """Read 16-bit little-endian word."""
    return struct.unpack('<H', f.read(2))[0]


def read_smallint(f):
    """Read 16-bit little-endian signed integer."""
    return struct.unpack('<h', f.read(2))[0]


def read_longint(f):
    """Read 32-bit little-endian integer."""
    return struct.unpack('<I', f.read(4))[0]


def write_word(f, val):
    """Write 16-bit little-endian word."""
    f.write(struct.pack('<H', val))


def write_smallint(f, val):
    """Write 16-bit little-endian signed integer."""
    f.write(struct.pack('<h', val))


def write_longint(f, val):
    """Write 32-bit little-endian integer."""
    f.write(struct.pack('<I', val))


class Paragraph:
    def __init__(self, wrap, text, offset_map=None):
        self.wrap = wrap
        self.text = text  # UTF-8 string
        self.offset_map = offset_map  # CP437 byte offset -> UTF-8 byte offset


class CrossRef:
    def __init__(self, ref, offset, length):
        self.ref = ref
        self.offset = offset
        self.length = length


class Topic:
    def __init__(self):
        self.paragraphs = []
        self.crossrefs = []


class HelpIndex:
    def __init__(self):
        self.contexts = []  # List of (context, position) tuples


def read_topic(f):
    """Read a topic from the file."""
    topic = Topic()

    # Read paragraph count
    para_count = read_smallint(f)

    for _ in range(para_count):
        size = read_smallint(f)
        wrap = f.read(1)[0] != 0
        text_bytes = f.read(size)
        offset_map = build_byte_offset_map(text_bytes)
        text = convert_text(text_bytes)
        topic.paragraphs.append(Paragraph(wrap, text, offset_map))

    # Read cross-reference count
    xref_count = read_smallint(f)

    for _ in range(xref_count):
        ref = read_word(f)
        offset = read_smallint(f)
        length = f.read(1)[0]
        topic.crossrefs.append(CrossRef(ref, offset, length))

    return topic


def adjust_crossref_offset(topic, cp437_offset):
    """Convert a cross-ref offset from CP437 bytes to UTF-8 bytes.

    Cross-ref offsets are positions in the concatenated paragraph texts.
    """
    # Walk through paragraphs to find which paragraph contains this offset
    cumulative_cp437 = 0
    cumulative_utf8 = 0
    for para in topic.paragraphs:
        # Original CP437 size is len(offset_map) - 1
        cp437_size = len(para.offset_map) - 1
        if cumulative_cp437 + cp437_size > cp437_offset:
            # Offset is within this paragraph
            local_offset = cp437_offset - cumulative_cp437
            return cumulative_utf8 + para.offset_map[local_offset]
        cumulative_cp437 += cp437_size
        cumulative_utf8 += len(para.text.encode('utf-8'))
    # Offset is at or past the end
    return cumulative_utf8


def write_topic(f, topic):
    """Write a topic to the file, return bytes written."""
    start_pos = f.tell()

    # Write ObjType for THelpTopic
    write_word(f, 10000)

    # Write paragraph count
    write_smallint(f, len(topic.paragraphs))

    for para in topic.paragraphs:
        # Convert UTF-8 string back to bytes
        text_bytes = para.text.encode('utf-8')
        write_smallint(f, len(text_bytes))
        f.write(bytes([1 if para.wrap else 0]))
        f.write(text_bytes)

    # Write cross-reference count
    write_smallint(f, len(topic.crossrefs))

    for xref in topic.crossrefs:
        # Adjust offset from CP437 to UTF-8 byte positions
        new_offset = adjust_crossref_offset(topic, xref.offset)
        write_word(f, xref.ref)
        write_smallint(f, new_offset)
        f.write(bytes([xref.length]))

    return f.tell() - start_pos


def convert_help_file(input_path, output_path):
    """Convert a help file from CP437 to UTF-8."""

    with open(input_path, 'rb') as f:
        # Read header
        magic = f.read(4)
        if magic != b'FBHF':
            raise ValueError(f"Invalid magic: {magic}")

        size = read_longint(f)
        index_pos = read_longint(f)

        print(f"Magic: {magic}")
        print(f"Size: {size}")
        print(f"Index position: {index_pos}")

        # Read topics
        topics = []
        topic_positions = []

        # Seek to index to find topic positions
        f.seek(index_pos)
        obj_type = read_word(f)
        if obj_type != 10001:
            raise ValueError(f"Expected THelpIndex (10001), got {obj_type}")

        used = read_word(f)
        idx_size = read_word(f)
        print(f"Index: used={used}, size={idx_size}")

        contexts = []
        for _ in range(idx_size):
            contexts.append(read_word(f))

        positions = []
        for _ in range(idx_size):
            positions.append(read_longint(f))

        # Read all topics
        topic_data = {}
        for i in range(used):
            ctx = contexts[i]
            pos = positions[i]
            if pos > 0:
                f.seek(pos)
                obj_type = read_word(f)
                if obj_type != 10000:
                    print(f"Warning: Expected THelpTopic (10000), got {obj_type} at pos {pos}")
                    continue
                topic = read_topic(f)
                topic_data[ctx] = topic
                print(f"  Topic {ctx} at {pos}: {len(topic.paragraphs)} paragraphs, {len(topic.crossrefs)} xrefs")

    # Write converted file
    with open(output_path, 'wb') as f:
        # Write header placeholder
        f.write(b'FBHF')
        write_longint(f, 0)  # Size placeholder
        write_longint(f, 0)  # Index position placeholder

        # Write topics and record positions
        new_positions = {}
        for ctx in sorted(topic_data.keys()):
            new_positions[ctx] = f.tell()
            write_topic(f, topic_data[ctx])

        # Record index position
        new_index_pos = f.tell()

        # Write index
        write_word(f, 10001)  # ObjType for THelpIndex
        write_word(f, used)
        write_word(f, idx_size)

        # Write contexts
        for i in range(idx_size):
            write_word(f, contexts[i])

        # Write positions
        for i in range(idx_size):
            ctx = contexts[i]
            if ctx in new_positions:
                write_longint(f, new_positions[ctx])
            else:
                write_longint(f, positions[i])

        # Update header
        new_size = f.tell() - 8
        f.seek(4)
        write_longint(f, new_size)
        write_longint(f, new_index_pos)

    print(f"\nConverted {input_path} -> {output_path}")
    print(f"New index position: {new_index_pos}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input.hlp output.hlp")
        sys.exit(1)

    convert_help_file(sys.argv[1], sys.argv[2])
