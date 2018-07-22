#Creating a thumbnail for an image. Those are reduced-size versions
#of pictures but still contains all of the most important aspects
#of an image

from PIL import Image

size = (10, 10)
saved = "Pogbum2.jpg"

try:
    im = Image.open("Pogbum.jpg")
    #Original size,format and mode of the image
    print(im.format,im.size,im.mode)
except:
    print ("Unable to load image")

im.thumbnail(size)
im.save(saved)
im.show()
#Final size,format and mode of the image
im2 = Image.open("Pogbum2.jpg")
print(im2.format,im2.size,im2.mode)
