% Script: Reparar_Datos_V2.m
clear; clc;

archivo_origen = 'Datos.csv';

if ~exist(archivo_origen, 'file')
    error(['No encuentro el archivo ' archivo_origen]);
end

disp('1. Leyendo archivo original...');
% Leer todo el texto
texto = fileread(archivo_origen);

% -----------------------------------------------------------
% REPARACIÓN DE CARACTERES
% -----------------------------------------------------------
disp('2. Reemplazando caracteres (Latino -> Anglosajón)...');
% 1. Reemplazar punto y coma (;) por espacio (separador de columnas)
texto_arreglado = strrep(texto, ';', ' ');

% 2. Reemplazar coma (,) por punto (.) (decimales)
texto_arreglado = strrep(texto_arreglado, ',', '.');

% 3. Guardar en archivo temporal
fid = fopen('Datos_Limpios.txt', 'w');
fwrite(fid, texto_arreglado);
fclose(fid);

% -----------------------------------------------------------
% LECTURA DE DATOS NUMÉRICOS
% -----------------------------------------------------------
disp('3. Importando números (saltando encabezado)...');

try
    % Usamos dlmread.
    % Argumentos: 'NombreArchivo', 'Delimitador(espacio)', 'FilaInicio(1)', 'ColumnaInicio(0)'
    % FilaInicio = 1 significa que salta la fila 0 (los títulos) y empieza en la 1.
    datos = dlmread('Datos_Limpios.txt', ' ', 1, 0);
catch
    error('Error al leer Datos_Limpios.txt. Verifica que no esté abierto en otro programa.');
end

% -----------------------------------------------------------
% ASIGNACIÓN Y GUARDADO
% -----------------------------------------------------------
Y = datos(:,1);
C = datos(:,2);
N = datos(:,3);

disp('-------------------------------------------');
disp('VERIFICACIÓN DE ESCALA:');
disp(['Primer valor de Y: ', num2str(Y(1))]);
disp(['Primer valor de C: ', num2str(C(1))]);

% Verificación automática
if abs(C(1)) > 1
    disp(' ALERTA: Los datos siguen pareciendo grandes (¿Millones?).');
    disp(' Intenta revisar si tu Excel original tenía puntos de miles.');
else
    disp(' CORRECTO: Los datos parecen ser decimales (Ciclos/Tasas).');
end

% Guardar .mat final
save Datos_RBC.mat Y C N;
disp('-------------------------------------------');
disp('¡Archivo Datos_RBC.mat generado con éxito!');
disp('Ahora ejecuta: dynare RBC_SMM');

