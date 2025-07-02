import pygame
import sys
import time

# 1. Comprueba si se pasó un nombre de archivo
if len(sys.argv) < 2:
    print("Error: Debes especificar el archivo MP3 a reproducir.")
    print("Uso: python reproductor.py mi_cancion.mp3")
    sys.exit(1) # Sale del script si no hay argumento

# 2. El nombre del archivo es el primer argumento
archivo_mp3 = sys.argv[1]

try:
    # 3. Inicializa pygame y reproduce el archivo
    pygame.init()
    pygame.mixer.music.load(archivo_mp3)
    pygame.mixer.music.play()
    print(f"Reproduciendo: {archivo_mp3}")

    while pygame.mixer.music.get_busy():
        time.sleep(1)

except pygame.error as e:
    print(f"Error al reproducir el archivo: {e}")
