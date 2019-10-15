# R_WindPRO
 Imitador R de herramientas WindPRO 
 
 Resumen: 
 1. Crea una lista con una serie temporal (ts) definida por las fechas YYYY, MM, DD y el intervalo 'by'
 2. Calcula DEM sencillo (solo terreno)
 3. Calcula DEMm (DEM con la modificación en la zona de los aerogeneradores). Estas celdas se elevan al valor escrito en sahder$alt (180m por defecto).
 4. Calculo de doShadow (paquete insol) sobre el DEM para cada ts --> Guarda todos los raster en un raster stack
 5. Calculo de doShadow (paquete insol) sobre el DEMm para cada ts --> Guarda todos los raster en un raster stack
 6. Cálculo de diferencian entre DEMm-DEM --> DEMmdif. Este sería el raster de sombreado producido  por los aerogeneradores.
 7. Muestreo del DEMmdif en los centroides de las viviendas (asentamientos). El número de contactos de los puntos con el valor superpuesto de sombreados será el valor en horas de sombreado para el periodo estudiado.
 7. Exportados: 
    - RESULTS: excel con el valor de sombreado para cada vivienda.
    - ShadowMAP: raster de sombreado superpuesto con todos los intervalos de tiempo estudiados.
    - ShadosMAPc: contornos ("curvas de nivel") del ShadowMAP.
