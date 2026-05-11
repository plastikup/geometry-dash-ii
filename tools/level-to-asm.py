# This helper tool takes a level structure from in.txt and outputs a code-readable hexadecimal version of that level.

from datetime import datetime

# This lookup table is used to translate characters into their corresponding ascii byte on the 6502
ascii_char_lookup_table = r" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_‘abcdefghijklmnopqrstuvwxyz{|}~▒"
ascii_char_lookup_table_offset = 129

with open('tools/in.txt', 'r', encoding='utf-8') as file:
	compiled_level = []

	for line in file:
		line = line.strip()

		result = []
		current = line[0]
		count = 1

		# counting loop
		for char in line[1:]:
			if char == current: count += 1
			else:
				# translate char into ascii byte
				ascii_byte_dec = ascii_char_lookup_table.find(current) + ascii_char_lookup_table_offset
				ascii_byte = f"{ascii_byte_dec:02X}" # turn decimal to capitalized hexadecimal
				# turn count into hex
				count_byte = f"{count:02X}"
				# save result
				result.append(f"{ascii_byte}{count_byte}")
				# reset counter and current character
				current = char
				count = 1

		# flush last run
		result.append(f"{current.upper()}{count:02X}")
		# format into string and save
		compiled_level.append(f"{"".join(result)}\n")

	# get filename from current timestamp
	current_time_iso = datetime.now().isoformat()
	# write
	with open(f'tools/out/{current_time_iso}.txt', 'w', encoding='utf-8') as f:
		f.writelines(compiled_level)
