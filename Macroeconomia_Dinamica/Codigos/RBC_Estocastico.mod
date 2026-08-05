// =================================================================
// MODELO RBC ESTOCÁSTICO (KPR)
// Archivo: RBC_Estocastico.mod
// =================================================================

// 1. Variables Endógenas
// -----------------------------------------------------------------
var Y C K N I w r A;

// 2. Variables Exógenas (NUEVO)
// -----------------------------------------------------------------
// eps_A es el "ruido" o choque aleatorio a la productividad
varexo eps_A;

// 3. Parámetros
// -----------------------------------------------------------------
// Añadimos rho_A (persistencia) y sigma_A (volatilidad)
parameters alpha delta beta Ass phi rho_A sigma_A;

// 4. Calibración
// -----------------------------------------------------------------
alpha   = 0.36;
delta   = 0.05;
beta    = 0.99;
Ass     = 1.0;          // Nivel medio de productividad
phi     = 1.854940964;  // Calibrado para N_ss = 0.33

// Calibración del proceso estocástico (Valores estándar RBC)
rho_A   = 0.95;  // Alta persistencia (el choque dura varios periodos)
sigma_A = 0.01;  // Desviación estándar del 1%

// 5. Bloque del Modelo
// -----------------------------------------------------------------
model;
    // --- Ecuaciones Estándar (Iguales al determinista) ---
    // 1. Función de Producción
    Y = A * K(-1)^alpha * N^(1-alpha);

    // 2. Ley de Movimiento del Capital
    K = (1-delta)*K(-1) + Y - C;

    // 3. Inversión
    I = Y - C;

    // 4. Ecuación de Euler
    1/C = beta * (1/C(+1)) * (r(+1) + 1 - delta);

    // 5. Oferta de Trabajo (Intratemporal)
    phi * C = w * (1 - N);

    // 6. Precios de los factores
    r = alpha * Y / K(-1);
    w = (1-alpha) * Y / N;

    // --- Ecuación Modificada (Proceso AR(1)) ---
    // 7. Proceso de la Productividad (Log-lineal)
    // log(A_t) = (1-rho)*log(Ass) + rho*log(A_{t-1}) + eps_A
    // Esto asegura que A fluctúe alrededor de Ass y regrese a él.
    log(A) = (1-rho_A)*log(Ass) + rho_A*log(A(-1)) + eps_A;
end;

// 6. Estado Estacionario
// -----------------------------------------------------------------
// El punto de partida es el mismo que el modelo determinista
steady_state_model;
    A = Ass; // En el SS, los choques son cero
    N = 0.33;
    r = 1/beta - (1-delta);
    k_n = (r / (alpha * Ass)) ^ (1/(alpha-1));
    K = k_n * N;
    Y = Ass * K^alpha * N^(1-alpha);
    I = delta * K;
    C = Y - I;
    w = (1-alpha) * Y / N;
end;

// Calcular el SS primero para asegurar convergencia
steady;

// 7. Definición de los Choques (NUEVO)
// -----------------------------------------------------------------
shocks;
    // Definimos la varianza del error exógeno
    var eps_A = sigma_A^2;
end;

// ... (Todo el código anterior permanece IGUAL hasta llegar a stoch_simul) ...

// 8. Simulación Estocástica
// -----------------------------------------------------------------
// Agregamos 'nograph' para evitar que Octave se congele intentando abrir ventanas.
// Dynare calculará todo, guardará los datos, pero no dibujará.
stoch_simul(order=1, irf=40, relative_irf, nograph);

// 9. Verificación Manual de Resultados
// -----------------------------------------------------------------
// Como desactivamos los gráficos, vamos a pedirle a Dynare que nos muestre
// los primeros 10 periodos de la respuesta del Producto (Y) y el Consumo (C)
// ante el choque tecnológico para verificar que sí calculó.

printf('\n--- RESULTADOS DE LA IRF (Primeros 10 periodos) ---\n');
printf('Periodo \t Y_eps_A \t C_eps_A \t I_eps_A\n');
for i = 1:10
    printf('%d \t\t %f \t %f \t %f\n', i, oo_.irfs.Y_eps_A(i), oo_.irfs.C_eps_A(i), oo_.irfs.I_eps_A(i));
end
