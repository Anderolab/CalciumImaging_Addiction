function correlateFluorescenceWithBehavior_synchronized_means(Experiment_trial)
    % Definir la lista de experimentos
    experiment_names = fieldnames(Experiment_trial);

    % Seleccionar las sesiones que se desean analizar
    selected_sessions_idx = listdlg('PromptString', 'Selecciona las sesiones a analizar:', ...
                                    'SelectionMode', 'multiple', ...
                                    'ListString', experiment_names);
    if isempty(selected_sessions_idx)
        disp('No se seleccionaron sesiones. Proceso cancelado.');
        return;
    end
    
    % Definir los tipos de eventos disponibles
    all_event_types = {'R', 'K', 'U', 'W', 'L', 'N', 'J'};
    
    % Seleccionar los tipos de eventos que se desean analizar
    selected_event_types_idx = listdlg('PromptString', 'Selecciona los tipos de eventos a analizar:', ...
                                       'SelectionMode', 'multiple', ...
                                       'ListString', all_event_types);
    if isempty(selected_event_types_idx)
        disp('No se seleccionaron tipos de eventos. Proceso cancelado.');
        return;
    end
    
    % Obtener los eventos seleccionados
    selected_event_types = all_event_types(selected_event_types_idx);
    
    session_means = zeros(1, length(selected_sessions_idx)); % Media de ventanas ±1 segundo
    session_means_10s = zeros(1, length(selected_sessions_idx)); % Media de ventanas de los 10 segundos siguientes
    
    % Inicializar celdas para almacenar puntos individuales de cada sesión
    session_fluorescence_points = cell(1, length(selected_sessions_idx));
    session_fluorescence_points_10s = cell(1, length(selected_sessions_idx));

    % Variables para almacenar las medias de fluorescencia y los valores individuales
    session_mean_values = []; % Almacenar las medias de fluorescencia (altura de las barras)
    session_individual_values = {}; % Almacenar los puntos individuales de fluorescencia
    session_mean_values_10s = []; % Almacenar las medias de fluorescencia de los 10s
    session_individual_values_10s = {}; % Almacenar los puntos individuales de fluorescencia de los 10s

    % Proceso para cada sesión seleccionada
    for session_idx = 1:length(selected_sessions_idx)
        i = selected_sessions_idx(session_idx);
        experiment = Experiment_trial.(experiment_names{i});
        
        % Obtener los nombres de las grabaciones de calcio (subfolders)
        subfolder_names = fieldnames(experiment);
        subfolder_names = subfolder_names(~ismember(subfolder_names, {'StartTime', 'EndTime', 'R', 'K', 'U', 'W', 'L', 'N', 'J'}));

        % Seleccionar las grabaciones de calcio que se desean analizar
        selected_subfolders_idx = listdlg('PromptString', ['Selecciona las grabaciones para ', experiment_names{i}], ...
                                          'SelectionMode', 'multiple', ...
                                          'ListString', subfolder_names);
        if isempty(selected_subfolders_idx)
            disp(['No se seleccionaron grabaciones para ', experiment_names{i}, '. Se omitirá esta sesión.']);
            continue;
        end

        % Proceso de selección de neuronas buenas para cada grabación (subcarpeta)
        good_neurons_files = cell(1, length(subfolder_names));
        for j = selected_subfolders_idx
            % Solicitar el archivo de buenas neuronas (opcional)
            [file, path] = uigetfile('*.mat', ['Selecciona archivo de buenas neuronas para ', subfolder_names{j}], 'MultiSelect', 'off');
            if isequal(file, 0)  % Si el usuario cancela la selección
                disp(['No se seleccionó archivo para ', subfolder_names{j}, '. Se usarán todas las neuronas.']);
                good_neurons_files{j} = []; % Guardar un valor vacío si no se selecciona archivo
            else
                % Cargar archivo de buenas neuronas
                good_neurons_files{j} = load(fullfile(path, file));
                disp(['Archivo de buenas neuronas seleccionado para ', subfolder_names{j}]);
            end
        end

        % Variables para acumular las medias de fluorescencia de todas las ventanas en esta sesión
        session_fluorescence_windows = [];
        session_fluorescence_windows_10s = []; % Acumular las medias de 10 segundos posteriores
        
        % Procesar las grabaciones seleccionadas
        for j = selected_subfolders_idx
            subfolder = experiment.(subfolder_names{j});
            
            % Obtener el timestamp de la grabación de calcio (en milisegundos)
            calcium_time = subfolder.time;

            % Aplicar filtro de neuronas buenas si se seleccionó un archivo
            if ~isempty(good_neurons_files{j})
                good_neurons = good_neurons_files{j}.good_neurons; % Usar la variable good_neurons del archivo cargado
                FiltTraces_good = subfolder.FiltTraces(:, good_neurons); % Filtrar trazas de neuronas buenas
                global_fluorescence = mean(FiltTraces_good, 2); % Fluorescencia global solo con neuronas buenas
                disp(['Usando solo las neuronas buenas para ', subfolder_names{j}]);
            else
                global_fluorescence = mean(subfolder.FiltTraces, 2); % Usar todas las neuronas
                disp(['Usando todas las neuronas para ', subfolder_names{j}]);
            end
            
            % Determinar el desfase temporal
            if j == selected_subfolders_idx(1)
                time_offset = 'first';
            else
                current_time = extractTimeFromSubfolder(subfolder_names{j});
                previous_time = extractTimeFromSubfolder(subfolder_names{1});
                time_offset = (current_time - previous_time) * 1000; % Desfase en milisegundos
            end
            
            % Obtener ventanas válidas centradas en eventos
            valid_event_windows = correlateRecordingWithEvents(experiment, subfolder, calcium_time, time_offset, subfolder_names{j}, global_fluorescence, selected_event_types);

            % Acumular las medias de ventanas válidas para esta sesión
            for k = 1:length(selected_event_types)
                event_type = selected_event_types{k};
                if isfield(valid_event_windows, event_type)
                    session_fluorescence_windows = [session_fluorescence_windows; valid_event_windows.(event_type)];
                end
                % Calcular y acumular ventanas de 10 segundos posteriores
                if isfield(valid_event_windows, [event_type, '_10s'])
                    session_fluorescence_windows_10s = [session_fluorescence_windows_10s; valid_event_windows.([event_type, '_10s'])];
                end
            end
        end
        disp(session_fluorescence_windows)
        
        % Guardar puntos individuales de cada sesión
        session_fluorescence_points{session_idx} = session_fluorescence_windows;
        session_fluorescence_points_10s{session_idx} = session_fluorescence_windows_10s;
        
        % Calcular media de fluorescencia para ventanas ±1 segundo en la sesión
        if ~isempty(session_fluorescence_windows)
            session_means(session_idx) = mean(session_fluorescence_windows);
            disp(['Media de fluorescencia centrada en eventos para la sesión ', experiment_names{i}, ': ', num2str(session_means(session_idx))]);
        else
            disp(['No se encontraron eventos válidos para la sesión ', experiment_names{i}]);
            session_means(session_idx) = NaN;
        end
        
        % Calcular media de fluorescencia para ventanas de 10 segundos en la sesión
        if ~isempty(session_fluorescence_windows_10s)
            session_means_10s(session_idx) = mean(session_fluorescence_windows_10s);
            disp(['Media de fluorescencia en 10s siguientes para la sesión ', experiment_names{i}, ': ', num2str(session_means_10s(session_idx))]);
        else
            session_means_10s(session_idx) = NaN;
        end
        
        % Almacenar las medias y los puntos individuales para esta sesión
        session_mean_values = [session_mean_values, session_means(session_idx)];
        session_individual_values{session_idx} = session_fluorescence_windows;
        session_mean_values_10s = [session_mean_values_10s, session_means_10s(session_idx)];
        session_individual_values_10s{session_idx} = session_fluorescence_windows_10s;
    end
    
    % Calcular error estándar para cada sesión
    session_se = cellfun(@(x) std(x) / sqrt(length(x)), session_fluorescence_points);
    session_se_10s = cellfun(@(x) std(x) / sqrt(length(x)), session_fluorescence_points_10s);
    
    % Graficar las medias de ventanas centradas por sesión con puntos individuales y barras de error
    figure;
    bar(session_means);
    hold on;
    for idx = 1:length(session_means)
        scatter(repmat(idx, size(session_fluorescence_points{idx})), session_fluorescence_points{idx}, 'k', 'filled');
        errorbar(idx, session_means(idx), session_se(idx), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
    end
    set(gca, 'XTickLabel', experiment_names(selected_sessions_idx), 'XTickLabelRotation', 45);
    ylabel('Media de fluorescencia');
    title('Media de fluorescencia centrada en eventos por sesión');
    hold off;
    
    % Graficar las medias de 10 segundos posteriores por sesión con puntos individuales y barras de error
    figure;
    bar(session_means_10s);
    hold on;
    for idx = 1:length(session_means_10s)
        scatter(repmat(idx, size(session_fluorescence_points_10s{idx})), session_fluorescence_points_10s{idx}, 'k', 'filled');
        errorbar(idx, session_means_10s(idx), session_se_10s(idx), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
    end
    set(gca, 'XTickLabel', experiment_names(selected_sessions_idx), 'XTickLabelRotation', 45);
    ylabel('Media de fluorescencia en 10s');
    title('Media de fluorescencia en 10 segundos posteriores a eventos por sesión');
    hold off;
    
    % Crear una tabla para exportar a Excel
    num_sessions = length(selected_sessions_idx);
    excel_data = table;
    for idx = 1:num_sessions
        session_name = experiment_names{selected_sessions_idx(idx)};
        
        % Medias de fluorescencia por sesión
        excel_data.(['Media_' session_name]) = session_mean_values(idx);
        excel_data.(['Media_10s_' session_name]) = session_mean_values_10s(idx);
        
        % Valores individuales de fluorescencia por sesión
        excel_data.(['Individual_' session_name]) = {session_individual_values{idx}};
        excel_data.(['Individual_10s_' session_name]) = {session_individual_values_10s{idx}};
    end
    
    % Guardar en archivo Excel
    filename = 'Fluorescencia_Sesiones.xlsx';
    writetable(excel_data, filename, 'Sheet', 1);
    disp(['Datos guardados en el archivo Excel: ', filename]);
    
    % Mostrar las variables generadas en el espacio de trabajo
    assignin('base', 'session_mean_values', session_mean_values);
    assignin('base', 'session_individual_values', session_individual_values);
    assignin('base', 'session_mean_values_10s', session_mean_values_10s);
    assignin('base', 'session_individual_values_10s', session_individual_values_10s);
end






%%
% Función para binarizar eventos según el tiempo de la grabación
function binarized_vector = binarizeEvents(time_vector, event_times_ms)
    binarized_vector = zeros(length(time_vector), 1);
    for i = 1:length(event_times_ms)
        event_time = event_times_ms(i);
        % Encuentra el índice más cercano en el tiempo de la grabación
        closest_index = findClosestIndex(time_vector, event_time);
        binarized_vector(closest_index) = 1;
    end
end

%% Función de correlación para incluir las ventanas de ±1 segundo y de 10 segundos
function [valid_event_windows] = correlateRecordingWithEvents(experiment, subfolder, calcium_time, time_offset, recording_name, global_fluorescence, event_types)
    % Graficar la fluorescencia global
    figure;
    plot(calcium_time / 1000, global_fluorescence, 'b');
    hold on;

    % Definir colores para cada tipo de evento
    colors = lines(length(event_types)); % Usar diferentes colores para los eventos
    
    % Inicializar estructura para almacenar ventanas válidas de fluorescencia por evento
    valid_event_windows = struct();

    % Procesar los tipos de eventos seleccionados
    for k = 1:length(event_types)
        event_type = event_types{k};
        event_times = experiment.(event_type);
        
        if isempty(event_times)
            continue;
        end

        % Convertir eventos de centisegundos a milisegundos
        event_times_ms = event_times * 10;

        if ~ischar(time_offset) % Ajustar por desfase
            event_times_ms = event_times_ms - time_offset;
        end

        % Filtrar eventos dentro del rango de grabación actual
        valid_event_times = event_times_ms(event_times_ms >= 0 & event_times_ms <= max(calcium_time));
        event_indices = arrayfun(@(x) findClosestIndex(calcium_time, x), valid_event_times);

        for ev_idx = 1:length(event_indices)
            event_frame = event_indices(ev_idx);
            
            % Calcular ventanas ±1 segundo alrededor del evento
            time_window = 1000;
            start_frame = find(calcium_time >= calcium_time(event_frame) - time_window, 1, 'first');
            end_frame = find(calcium_time <= calcium_time(event_frame) + time_window, 1, 'last');
            if ~isempty(start_frame) && ~isempty(end_frame)
                window_fluorescence = global_fluorescence(start_frame:end_frame);
                mean_fluorescence = mean(window_fluorescence);
                if ~isfield(valid_event_windows, event_type)
                    valid_event_windows.(event_type) = [];
                end
                valid_event_windows.(event_type) = [valid_event_windows.(event_type); mean_fluorescence];
            end
            
            % Calcular ventana de 10 segundos posteriores al evento
            time_10s_window = 10000;
            end_10s_frame = find(calcium_time <= calcium_time(event_frame) + time_10s_window, 1, 'last');
            if ~isempty(end_10s_frame) && event_frame < end_10s_frame
                window_fluorescence_10s = global_fluorescence(event_frame:end_10s_frame);
                mean_fluorescence_10s = mean(window_fluorescence_10s);
                if ~isfield(valid_event_windows, [event_type, '_10s'])
                    valid_event_windows.([event_type, '_10s']) = [];
                end
                valid_event_windows.([event_type, '_10s']) = [valid_event_windows.([event_type, '_10s']); mean_fluorescence_10s];
            end
        end
    end
    hold off;
end



% Función para encontrar el índice más cercano en el timestamp
function index = findClosestIndex(time_vector, event_time)
    [~, index] = min(abs(time_vector - event_time));
end

% Función para extraer la hora desde el nombre de la carpeta
function time_seconds = extractTimeFromSubfolder(subfolder_name)
    time_pattern = regexp(subfolder_name, 'H(\d+)_M(\d+)_S(\d+)', 'tokens');
    
    if isempty(time_pattern)
        error('No se pudo extraer el tiempo del nombre de la carpeta');
    end
    
    time_parts = str2double(time_pattern{1});
    time_seconds = time_parts(1) * 3600 + time_parts(2) * 60 + time_parts(3); % Convertir a segundos
end


