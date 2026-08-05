// =================================================================
// MODELO RBC - ESTIMACIÓN SMM (CHOQUES ACTIVOS)
// Archivo: RBC_SMM.mod
// =================================================================

// 0. Configuración para evitar ventanas (Octave)
verbatim;
    if exist('OCTAVE_VERSION', 'builtin')
        set(0, 'DefaultFigureVisible', 'off');
    end
end;

// 1. Variables
var Y C I K N w r A;
varexo eps_A;

// 2. Parámetros
// Eliminamos 'sigma_A' porque estimaremos 'stderr eps_A' directamente
parameters alpha delta beta Ass phi rho_A;

// 3. Calibración Inicial
alpha   = 0.36;
delta   = 0.05;
beta    = 0.99;
Ass     = 1.0;
phi     = 1.855;
rho_A   = 0.95;

// 4. Bloque del Modelo
model;
    Y = A * K(-1)^alpha * N^(1-alpha);
    K = (1-delta)*K(-1) + Y - C;
    I = Y - C;
    1/C = beta * (1/C(+1)) * (r(+1) + 1 - delta);
    phi * C = w * (1 - N);
    r = alpha * Y / K(-1);
    w = (1-alpha) * Y / N;

    // Ecuación del choque
    // Nota: eps_A aquí tendrá la varianza que estimemos abajo
    log(A) = (1-rho_A)*log(Ass) + rho_A*log(A(-1)) + eps_A;
end;

// 5. Estado Estacionario
steady_state_model;
    A = Ass;
    r = 1/beta - (1-delta);
    k_n_ratio = (r / (alpha * Ass)) ^ (1/(alpha-1));

    w_val = (1-alpha) * Ass * k_n_ratio^alpha;
    y_n_val = Ass * k_n_ratio^alpha;
    c_n_val = y_n_val - delta * k_n_ratio;

    // Ajuste endógeno de N
    N = w_val / (phi * c_n_val + w_val);

    K = k_n_ratio * N;
    Y = y_n_val * N;
    I = delta * K;
    C = c_n_val * N;
    w = w_val;
end;

steady;

// 6. Estimación de Parámetros
estimated_params;
    // Persistencia
    rho_A, 0.95, 0.001, 0.999;

    // Volatilidad del Choque
    // USAMOS 'stderr' PARA QUE DYNARE SEPA QUE ES LA VARIANZA DEL CHOQUE
    stderr eps_A, 0.01, 0.0001, 0.10;

    // Preferencia Ocio
    phi, 1.85, 1.0, 10.0;
end;

estimated_params_init(use_calibration);
end;

// =========================================================================
// MÉTODO DE MOMENTOS SIMULADOS (SMM)
// =========================================================================

varobs Y C N;

matched_moments;
    Y*Y; C*C; N*N;
    Y*C; Y*N; C*N;
    Y*Y(-1); C*C(-1); N*N(-1);
end;

method_of_moments(
      mom_method = SMM
    , datafile   = 'Datos_RBC.mat' // Hay que asegurarse de usar el archivo reparado (decimales)
    , order = 1
    , weighting_matrix = ['DIAGONAL','OPTIMAL']
    , se_tolx = 1e-6

    // Aumentamos simulación para reducir ruido numérico (varianzas != 0)
    , simulation_multiple = 5

    , prefilter = 1
    , TeX
    , mode_compute = 4
    , optim = ('TolFun', 1e-6, 'TolX', 1e-6)
    , nograph
    , nodisplay
);
