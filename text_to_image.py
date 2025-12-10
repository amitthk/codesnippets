from PIL import Image, ImageDraw, ImageFont

# Configuration
NUM_COLUMNS = 12
INPUT_FILE = "linux.org"
OUTPUT_FILE = "linux_commands_wallpaper_dark.png"

# read text
with open(INPUT_FILE, "r", encoding="utf8") as f:
    text = f.read()

# split into columns
lines = text.split("\n")
col_height = len(lines) // NUM_COLUMNS + 1
columns = [lines[i*col_height:(i+1)*col_height] for i in range(NUM_COLUMNS)]

# image settings
font = ImageFont.load_default()
col_width = 280
col_padding = 5
margin = 40
bottom_margin = 80
img_width = col_width * NUM_COLUMNS + col_padding * (NUM_COLUMNS - 1) + margin * 2
img_height = (len(columns[0]) * 15) + margin + bottom_margin

image = Image.new("RGB", (img_width, img_height), "black")
draw = ImageDraw.Draw(image)

# draw text
for c, col in enumerate(columns):
    x = margin + c * (col_width + col_padding)
    y = margin
    for line in col:
        draw.text((x, y), line, fill="white", font=font)
        y += 15

image.save(OUTPUT_FILE)
