#!/usr/bin/env python3
"""
Script pour générer l'icône de l'application CityCare
Crée une image PNG avec un gradient bleu et une icône de ville
"""

from PIL import Image, ImageDraw
import numpy as np

def create_app_icon(size=1024):
    """Crée une icône d'application avec le design du logo"""
    # Créer une image avec fond transparent
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Couleurs du gradient (primaryColor vers primaryVariant)
    color1 = np.array([30, 58, 138])  # #1E3A8A
    color2 = np.array([59, 130, 246])  # #3B82F6
    
    # Créer un array numpy pour le gradient
    arr = np.zeros((size, size, 4), dtype=np.uint8)
    
    for y in range(size):
        for x in range(size):
            # Gradient diagonal de haut-gauche vers bas-droite
            ratio_x = x / size
            ratio_y = y / size
            gradient_ratio = (ratio_x + ratio_y) / 2
            
            color = color1 * (1 - gradient_ratio) + color2 * gradient_ratio
            arr[y, x] = [int(color[0]), int(color[1]), int(color[2]), 255]
    
    # Convertir en image
    gradient_img = Image.fromarray(arr, 'RGBA')
    
    # Créer un masque pour les coins arrondis
    radius = int(size * 0.2)  # 20% du rayon
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=radius, fill=255)
    
    # Appliquer le masque au gradient
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(gradient_img, (0, 0), mask)
    
    # Dessiner l'icône de ville (simplifiée) sur l'image finale
    draw = ImageDraw.Draw(output)
    icon_size = int(size * 0.4)
    icon_x = size // 2
    icon_y = size // 2
    
    # Dessiner des rectangles pour représenter des bâtiments
    building_width = icon_size // 3
    building_height = icon_size // 2
    
    # Bâtiment gauche
    left_x = icon_x - building_width - building_width // 3
    draw.rectangle(
        [(left_x - building_width // 2, icon_y - building_height // 2),
         (left_x + building_width // 2, icon_y + building_height // 2)],
        fill=(255, 255, 255, 255)
    )
    
    # Bâtiment central (plus haut)
    center_height = int(building_height * 1.2)
    draw.rectangle(
        [(icon_x - building_width // 2, icon_y - center_height // 2),
         (icon_x + building_width // 2, icon_y + center_height // 2)],
        fill=(255, 255, 255, 255)
    )
    
    # Bâtiment droit
    right_x = icon_x + building_width + building_width // 3
    draw.rectangle(
        [(right_x - building_width // 2, icon_y - building_height // 2),
         (right_x + building_width // 2, icon_y + building_height // 2)],
        fill=(255, 255, 255, 255)
    )
    
    # Dessiner des fenêtres sur les bâtiments
    window_size = building_width // 4
    window_spacing = building_width // 3
    
    # Fenêtres sur le bâtiment gauche
    for i in range(2):
        for j in range(2):
            window_x = left_x - building_width // 2 + window_spacing + j * window_spacing
            window_y = icon_y - building_height // 2 + window_spacing + i * window_spacing
            draw.rectangle(
                [(window_x - window_size // 2, window_y - window_size // 2),
                 (window_x + window_size // 2, window_y + window_size // 2)],
                fill=(30, 58, 138, 255)  # Couleur bleue pour les fenêtres
            )
    
    # Fenêtres sur le bâtiment central
    for i in range(3):
        for j in range(2):
            window_x = icon_x - building_width // 2 + window_spacing + j * window_spacing
            window_y = icon_y - center_height // 2 + window_spacing + i * window_spacing
            draw.rectangle(
                [(window_x - window_size // 2, window_y - window_size // 2),
                 (window_x + window_size // 2, window_y + window_size // 2)],
                fill=(30, 58, 138, 255)
            )
    
    # Fenêtres sur le bâtiment droit
    for i in range(2):
        for j in range(2):
            window_x = right_x - building_width // 2 + window_spacing + j * window_spacing
            window_y = icon_y - building_height // 2 + window_spacing + i * window_spacing
            draw.rectangle(
                [(window_x - window_size // 2, window_y - window_size // 2),
                 (window_x + window_size // 2, window_y + window_size // 2)],
                fill=(30, 58, 138, 255)
            )
    
    return output

if __name__ == '__main__':
    print("Génération de l'icône de l'application...")
    icon = create_app_icon(1024)
    icon.save('assets/app_icon.png', 'PNG')
    print("✓ Icône générée avec succès: assets/app_icon.png")
    print("  Taille: 1024x1024 pixels")
