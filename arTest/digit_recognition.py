import cv2
import numpy as np
from imutils.perspective import four_point_transform
from imutils import contours
import imutils

# Diccionario para reconocer dígitos en displays de 7 segmentos
DIGITS_LOOKUP = {
    (1, 1, 1, 0, 1, 1, 1): 0,
    (0, 0, 1, 0, 0, 1, 0): 1,
    (1, 0, 1, 1, 1, 1, 0): 2,
    (1, 0, 1, 1, 0, 1, 1): 3,
    (0, 1, 1, 1, 0, 1, 0): 4,
    (1, 1, 0, 1, 0, 1, 1): 5,
    (1, 1, 0, 1, 1, 1, 1): 6,
    (1, 0, 1, 0, 0, 1, 0): 7,
    (1, 1, 1, 1, 1, 1, 1): 8,
    (1, 1, 1, 1, 0, 1, 1): 9
}

def preprocess_image(image_path):
    # Leer y redimensionar la imagen
    image = cv2.imread(image_path)
    image = imutils.resize(image, height=500)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Mejorar contraste y reducir ruido
    blurred = cv2.GaussianBlur(gray, (7, 7), 0)
    edged = cv2.Canny(blurred, 50, 200, 255)
    
    return image, gray, edged

def find_display(edged, gray):
    # Encontrar contornos
    cnts = cv2.findContours(edged.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)
    
    displayCnt = None
    for c in cnts:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:  # Buscar contornos con forma rectangular
            displayCnt = approx
            break
    
    if displayCnt is None:
        raise ValueError("No se pudo encontrar un display en la imagen.")
    
    warped = four_point_transform(gray, displayCnt.reshape(4, 2))
    return warped

def recognize_digits(warped):
    # Umbralizar para segmentar los segmentos de los dígitos
    thresh = cv2.threshold(warped, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (1, 5))
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)

    # Encontrar contornos de posibles dígitos
    cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    digitCnts = []

    for c in cnts:
        (x, y, w, h) = cv2.boundingRect(c)
        if w >= 10 and (h >= 25 and h <= 50):  # Prueba con rangos más amplios
            digitCnts.append(c)

    digitCnts = contours.sort_contours(digitCnts, method="left-to-right")[0]
    digits = []

    # Reconocer dígitos
    for c in digitCnts:
        (x, y, w, h) = cv2.boundingRect(c)
        roi = thresh[y:y+h, x:x+w]
        (roiH, roiW) = roi.shape
        (dW, dH) = (int(roiW * 0.25), int(roiH * 0.15))
        dHC = int(roiH * 0.05)

        segments = [
            ((0, 0), (w, dH)),    # top
            ((0, 0), (dW, h // 2)),  # top-left
            ((w - dW, 0), (w, h // 2)),  # top-right
            ((0, (h // 2) - dHC), (w, (h // 2) + dHC)),  # center
            ((0, h // 2), (dW, h)),  # bottom-left
            ((w - dW, h // 2), (w, h)),  # bottom-right
            ((0, h - dH), (w, h))   # bottom
        ]
        on = [0] * len(segments)

        for (i, ((xA, yA), (xB, yB))) in enumerate(segments):
            segROI = roi[yA:yB, xA:xB]
            total = cv2.countNonZero(segROI)
            area = (xB - xA) * (yB - yA)

            if total / float(area) > 0.5:
                on[i] = 1

        digit = DIGITS_LOOKUP.get(tuple(on), -1)  # Maneja casos desconocidos
        if digit == -1:
            continue
        digits.append(digit)

    return digits

def main(image_path):
    image, gray, edged = preprocess_image(image_path)
    warped = find_display(edged, gray)
    digits = recognize_digits(warped)
    print("Dígitos reconocidos:", digits)

# Ejecutar el script con una imagen de ejemplo
main('aaaa.jpg')
