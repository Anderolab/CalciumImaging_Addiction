function Experiment_trial = createExperimentStructureRoberto()

    % Definir las rutas base
    base_paths = {...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_25_2024_FR1',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_26_2024_FR1',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_27_2024_FR1',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_28_2024_FR1',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_29_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_02_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_03_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_04_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_05_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_07_2024_PR',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_09_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_10_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_11_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_12_2024_SHOCK',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_13_2024_POSTSHOCK',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_17_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_19_2024_CUE',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_22_2024_FR5',...
        'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Ms roberto\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_23_2024_REVERSAL'
    };
    
    % Inicializar la estructura principal
    Experiment_trial = struct();

    for i = 1:length(base_paths)
        base_path = base_paths{i};
        [~, field_name, ~] = fileparts(base_path);
        
        % Asegurarse de que el nombre del campo no empieza con un número
        field_name = ['Exp_' field_name];
        
        % Crear campo para cada ruta base
        Experiment_trial.(field_name) = struct();
        
        % Buscar y leer el archivo de texto
        text_files = dir(fullfile(base_path, '*.txt'));
        if ~isempty(text_files)
            text_file_path = fullfile(base_path, text_files(1).name);
            disp(['Leyendo archivo de texto: ' text_file_path]);
            file_content = fileread(text_file_path);
            
            % Mostrar el contenido del archivo para depuración
            disp('Contenido del archivo de texto:');
            disp(file_content);
            
            % Extraer la información del archivo de texto
            start_time = extractBetween(file_content, 'Start Time: ', newline);
            end_time = extractBetween(file_content, 'End Time: ', newline);
            R = extractDataSection(file_content, 'R:');
            K = extractDataSection(file_content, 'K:');
            J = extractDataSection(file_content, 'J:');
            U = extractDataSection(file_content, 'U:');
            W = extractDataSection(file_content, 'W:');
            L = extractDataSection(file_content, 'L:');
            N = extractDataSection(file_content, 'N:');
            
            % Añadir los datos del archivo de texto a la estructura
            if ~isempty(start_time)
                Experiment_trial.(field_name).StartTime = strtrim(start_time{1});
                disp(['Start Time: ' Experiment_trial.(field_name).StartTime]);
            end
            if ~isempty(end_time)
                Experiment_trial.(field_name).EndTime = strtrim(end_time{1});
                disp(['End Time: ' Experiment_trial.(field_name).EndTime]);
            end
            if ~isempty(R)
                Experiment_trial.(field_name).R = R;
                disp('Datos R extraídos.');
            end
            if ~isempty(K)
                Experiment_trial.(field_name).K = K;
                disp('Datos K extraídos.');
            end
            
            if ~isempty(U)
                Experiment_trial.(field_name).U = U;
                disp('Datos U extraídos.');
            end
            if ~isempty(W)
                Experiment_trial.(field_name).W = W;
                disp('Datos W extraídos.');
            end
            if ~isempty(J)
                Experiment_trial.(field_name).J = J;
                disp('Datos J extraídos.');
            end
            if ~isempty(N)
                Experiment_trial.(field_name).N = N;
                disp('Datos N extraídos.');
            end
            if ~isempty(L)
                Experiment_trial.(field_name).L = L;
                disp('Datos L extraídos.');
            end            
        end
        
        % Buscar subcarpetas
        subfolders = dir(base_path);
        subfolders = subfolders([subfolders.isdir] & ~ismember({subfolders.name}, {'.', '..'}));
        
        for j = 1:length(subfolders)
            subfolder_path = fullfile(base_path, subfolders(j).name);
            
            % Buscar cualquier archivo .mat dentro de la subcarpeta
            mat_files = dir(fullfile(subfolder_path, '*.mat'));
            
            if ~isempty(mat_files)
                ms_file_path = fullfile(subfolder_path, mat_files(1).name);  % Coger el primer archivo .mat encontrado
                disp(['Cargando archivo: ' ms_file_path]);
                
                ms_data = load(ms_file_path);
                
                if isfield(ms_data, 'ms')  % Asegurarse de que el archivo contiene la variable 'ms'
                    ms = ms_data.ms;
                    
                    % Extraer los campos necesarios
                    FiltTraces = ms.FiltTraces;
                    RawTraces = ms.RawTraces;
                    
                    % Verificar si existe el campo 'time'
                    if isfield(ms, 'time')
                        time = ms.time;
                        % Añadir la subestructura con 'time' si existe
                        Experiment_trial.(field_name).(subfolders(j).name) = struct( ...
                            'FiltTraces', FiltTraces, ...
                            'RawTraces', RawTraces, ...
                            'time', time ...
                        );
                        disp(['Datos de subcarpeta ' subfolders(j).name ' añadidos con time a ' field_name]);
                    else
                        % Intentar leer timeStamps desde el archivo CSV
                        timeStampsFile = fullfile(subfolder_path, 'timeStamps.csv');
                        if exist(timeStampsFile, 'file')
                            disp(['Leyendo timeStamps desde ' timeStampsFile]);
                            try
                                % Leer la tabla de timeStamps
                                opts = detectImportOptions(timeStampsFile, 'Delimiter', ',');
                                timeStampsData = readtable(timeStampsFile, opts);
                                % Verificar si la columna 'Time Stamp (ms)' existe
                                if any(strcmp(timeStampsData.Properties.VariableNames, 'TimeStamp_ms_')) || any(strcmp(timeStampsData.Properties.VariableNames, 'Time_Stamp_(ms)'))
                                    if any(strcmp(timeStampsData.Properties.VariableNames, 'TimeStamp_ms_'))
                                        time = timeStampsData.('TimeStamp_ms_');
                                    else
                                        time = timeStampsData.('Time_Stamp_(ms)');
                                    end
                                    % Asegurarse de que time es un vector columna
                                    time = time(:);
                                    % Ajustar el primer valor a 0
                                    if ~isempty(time)
                                        time(1) = 0;
                                    end
                                    % Añadir la subestructura con 'time' obtenido del archivo CSV
                                    Experiment_trial.(field_name).(subfolders(j).name) = struct( ...
                                        'FiltTraces', FiltTraces, ...
                                        'RawTraces', RawTraces, ...
                                        'time', time ...
                                    );
                                    disp(['Datos de subcarpeta ' subfolders(j).name ' añadidos con time extraído de timeStamps.csv a ' field_name]);
                                else
                                    % Si no se encuentra la columna 'Time Stamp (ms)'
                                    Experiment_trial.(field_name).(subfolders(j).name) = struct( ...
                                        'FiltTraces', FiltTraces, ...
                                        'RawTraces', RawTraces ...
                                    );
                                    disp(['No se encontró la columna ''Time Stamp (ms)'' en ' timeStampsFile]);
                                    disp(['Datos de subcarpeta ' subfolders(j).name ' añadidos sin time a ' field_name]);
                                end
                            catch ME
                                % En caso de error al leer el archivo CSV
                                Experiment_trial.(field_name).(subfolders(j).name) = struct( ...
                                    'FiltTraces', FiltTraces, ...
                                    'RawTraces', RawTraces ...
                                );
                                disp(['Error al leer ' timeStampsFile ': ' ME.message]);
                                disp(['Datos de subcarpeta ' subfolders(j).name ' añadidos sin time a ' field_name]);
                            end
                        else
                            % Si no existe el archivo timeStamps.csv
                            Experiment_trial.(field_name).(subfolders(j).name) = struct( ...
                                'FiltTraces', FiltTraces, ...
                                'RawTraces', RawTraces ...
                            );
                            disp(['No se encontró el archivo ' timeStampsFile]);
                            disp(['Datos de subcarpeta ' subfolders(j).name ' añadidos sin time a ' field_name]);
                        end
                    end
                else
                    disp(['El archivo ' ms_file_path ' no contiene la variable ms']);
                end
            else
                disp(['No se encontró archivo .mat en la subcarpeta ' subfolder_path]);
            end
        end
    end
end

function data = extractDataSection(file_content, section)
    % Encuentra la sección específica y extrae los datos
    pattern = ['^' section '\s*\n'];
    section_start = regexp(file_content, pattern, 'start', 'lineanchors');
    disp(['section_start = ', num2str(section_start)]);
    if isempty(section_start)
        data = [];
        disp(['Sección ' section ' no encontrada.']);
        return;
    end
    
    % Encuentra el final de la sección
    next_section_pattern = '^[A-Z]:';
    section_end = regexp(file_content(section_start+length(section):end), next_section_pattern, 'lineanchors', 'once');
    if isempty(section_end)
        section_end = length(file_content);
    else
        section_end = section_start + length(section) + section_end - 2;
    end
    
    section_data = file_content(section_start:section_end);
    section_lines = splitlines(section_data);
    
    % Parsear los datos de la sección
    data = [];
    for k = 2:length(section_lines)
        line = section_lines{k};
        % Detenerse si encuentra una nueva sección
        if regexp(line, '^[A-Z]:')
            break;
        end
        % Eliminar prefijos como '0:', '5:', etc.
        line = regexprep(line, '^\s*\d+:\s*', '');
        % Reemplazar comas por puntos
        line = strrep(line, ',', '.');
        numbers = sscanf(line, '%f');
        if ~isempty(numbers)
            data = [data, numbers']; % Concatenar horizontalmente
        end
    end
    disp(['Datos de la sección ' section ' extraídos.']);
end
