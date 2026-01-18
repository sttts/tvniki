#!/usr/bin/env python3
"""Compile hilfe.txt to hilfe.hlp format.

This is a help compiler for Turbo Vision / Free Vision help files.
It reads text files with .topic directives and {cross-references}
and produces binary .hlp files.

Format:
  .topic TopicName           - Start a new topic (auto-assigned context ID)
  .topic TopicName=123       - Start a new topic with specific context ID
  {LinkText}                 - Cross-reference to topic named "LinkText"
  {LinkText:TopicName}       - Cross-reference with custom text

The output format is compatible with Free Vision's THelpFile.
"""

import struct
import sys
import re
from collections import OrderedDict


def write_word(f, val):
    """Write 16-bit little-endian word."""
    f.write(struct.pack('<H', val & 0xFFFF))


def write_smallint(f, val):
    """Write 16-bit little-endian signed integer."""
    f.write(struct.pack('<h', val))


def write_longint(f, val):
    """Write 32-bit little-endian integer."""
    f.write(struct.pack('<I', val))


class CrossRef:
    def __init__(self, ref, offset, length):
        self.ref = ref      # Context ID of target topic
        self.offset = offset  # Byte offset in paragraph text
        self.length = length  # Length of link text in characters


class Paragraph:
    def __init__(self, text, wrap=True):
        self.text = text  # UTF-8 string ending with \r
        self.wrap = wrap


class Topic:
    def __init__(self, name, context_id):
        self.name = name
        self.context_id = context_id
        self.paragraphs = []
        self.crossrefs = []


def parse_help_file(filename):
    """Parse a help text file and return topics dict and topic_names dict."""
    topics = OrderedDict()  # context_id -> Topic
    topic_names = {}  # name -> context_id
    current_topic = None
    next_context_id = 1  # Auto-assign context IDs starting from 1

    # First pass: collect all topic names and their context IDs
    with open(filename, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n\r')
            if line.startswith('.topic '):
                topic_def = line[7:].strip()
                if '=' in topic_def:
                    name, ctx_str = topic_def.split('=', 1)
                    name = name.strip()
                    context_id = int(ctx_str.strip())
                else:
                    name = topic_def
                    context_id = next_context_id
                    next_context_id += 1

                topic_names[name] = context_id
                if context_id >= next_context_id:
                    next_context_id = context_id + 1

    # Second pass: parse content
    with open(filename, 'r', encoding='utf-8') as f:
        current_para_lines = []

        def flush_paragraph():
            nonlocal current_para_lines
            if current_para_lines and current_topic:
                text = '\r'.join(current_para_lines) + '\r'
                current_topic.paragraphs.append(Paragraph(text))
            current_para_lines = []

        for line in f:
            line = line.rstrip('\n\r')

            if line.startswith('.topic '):
                # Flush previous paragraph
                flush_paragraph()

                topic_def = line[7:].strip()
                if '=' in topic_def:
                    name, ctx_str = topic_def.split('=', 1)
                    name = name.strip()
                    context_id = int(ctx_str.strip())
                else:
                    name = topic_def
                    context_id = topic_names[name]

                current_topic = Topic(name, context_id)
                topics[context_id] = current_topic
            elif current_topic is not None:
                current_para_lines.append(line)

        # Flush final paragraph
        flush_paragraph()

    return topics, topic_names


def process_crossrefs(topics, topic_names):
    """Find and process cross-references in topic paragraphs."""
    # Pattern for cross-references: {text} or {text:target}
    xref_pattern = re.compile(r'\{([^}:]+)(?::([^}]+))?\}')

    for topic in topics.values():
        new_paragraphs = []
        all_crossrefs = []
        cumulative_offset = 0

        for para in topic.paragraphs:
            text = para.text
            new_text = []
            last_end = 0

            for match in xref_pattern.finditer(text):
                link_text = match.group(1)
                target_name = match.group(2) if match.group(2) else link_text

                # Add text before the match
                new_text.append(text[last_end:match.start()])

                # Calculate byte offset for cross-ref (in UTF-8)
                offset_before = ''.join(new_text).encode('utf-8')
                byte_offset = cumulative_offset + len(offset_before)

                # Add the link text (without braces)
                new_text.append(link_text)

                # Look up target context ID
                if target_name in topic_names:
                    target_ctx = topic_names[target_name]
                    # Length is character count, not byte count
                    xref = CrossRef(target_ctx, byte_offset, len(link_text))
                    all_crossrefs.append(xref)
                else:
                    print(f"Warning: Unknown cross-reference target '{target_name}' in topic '{topic.name}'")

                last_end = match.end()

            # Add remaining text
            new_text.append(text[last_end:])
            final_text = ''.join(new_text)

            new_paragraphs.append(Paragraph(final_text, para.wrap))
            cumulative_offset += len(final_text.encode('utf-8'))

        topic.paragraphs = new_paragraphs
        topic.crossrefs = all_crossrefs


def write_topic(f, topic):
    """Write a topic to the file."""
    # Write ObjType for THelpTopic
    write_word(f, 10000)

    # Write paragraph count
    write_smallint(f, len(topic.paragraphs))

    for para in topic.paragraphs:
        text_bytes = para.text.encode('utf-8')
        write_smallint(f, len(text_bytes))
        f.write(bytes([1 if para.wrap else 0]))
        f.write(text_bytes)

    # Write cross-reference count
    write_smallint(f, len(topic.crossrefs))

    for xref in topic.crossrefs:
        write_word(f, xref.ref)
        write_smallint(f, xref.offset)
        f.write(bytes([xref.length]))


def compile_help_file(input_path, output_path):
    """Compile a help text file to binary format."""
    print(f"Compiling {input_path} -> {output_path}")

    topics, topic_names = parse_help_file(input_path)
    print(f"  Found {len(topics)} topics")

    process_crossrefs(topics, topic_names)

    with open(output_path, 'wb') as f:
        # Write header placeholder
        f.write(b'FBHF')
        write_longint(f, 0)  # Size placeholder
        write_longint(f, 0)  # Index position placeholder

        # Write topics and record positions
        topic_positions = {}
        for ctx, topic in topics.items():
            topic_positions[ctx] = f.tell()
            write_topic(f, topic)
            print(f"  Topic '{topic.name}' (ctx={ctx}): {len(topic.paragraphs)} paragraphs, {len(topic.crossrefs)} xrefs")

        # Record index position
        index_pos = f.tell()

        # Build sorted index
        contexts = sorted(topic_positions.keys())
        used = len(contexts)
        size = used  # Could add padding, but keeping it simple

        # Write index
        write_word(f, 10001)  # ObjType for THelpIndex
        write_word(f, used)
        write_word(f, size)

        # Write contexts
        for ctx in contexts:
            write_word(f, ctx)

        # Write positions
        for ctx in contexts:
            write_longint(f, topic_positions[ctx])

        # Update header
        new_size = f.tell() - 8
        f.seek(4)
        write_longint(f, new_size)
        write_longint(f, index_pos)

    print(f"  Output: {output_path} ({index_pos + 6 + used * 6} bytes)")


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} input.txt [output.hlp]")
        print(f"       {sys.argv[0]} --all  (compile all hilfe.*.txt files)")
        sys.exit(1)

    if sys.argv[1] == '--all':
        import glob
        # Compile all hilfe.*.txt files
        for txt_file in glob.glob('hilfe.*.txt'):
            # hilfe.en.txt -> hilfe.en.hlp
            hlp_file = txt_file[:-4] + '.hlp'
            compile_help_file(txt_file, hlp_file)
        # Also compile main hilfe.txt if it exists
        import os
        if os.path.exists('hilfe.txt'):
            compile_help_file('hilfe.txt', 'hilfe.hlp')
    else:
        input_path = sys.argv[1]
        if len(sys.argv) >= 3:
            output_path = sys.argv[2]
        else:
            output_path = input_path.rsplit('.', 1)[0] + '.hlp'
        compile_help_file(input_path, output_path)


if __name__ == '__main__':
    main()
