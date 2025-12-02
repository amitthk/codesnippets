from PIL import Image, ImageDraw, ImageFont

# read text
with open("linux.org", "r", encoding="utf8") as f:
    text = f.read()

# split into 6 columns
lines = text.split("\n")
col_height = len(lines) // 6 + 1
columns = [lines[i*col_height:(i+1)*col_height] for i in range(6)]

# image settings
font = ImageFont.load_default()
col_width = 300
padding = 20
img_width = col_width * 6 + padding * 2
img_height = (len(columns[0]) * 15) + padding * 2

image = Image.new("RGB", (img_width, img_height), "black")
draw = ImageDraw.Draw(image)

# draw text
for c, col in enumerate(columns):
    x = padding + c * col_width
    y = padding
    for line in col:
        draw.text((x, y), line, fill="white", font=font)
        y += 15

image.save("linux_commands_wallpaper.png")
