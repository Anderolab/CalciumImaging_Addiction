# Folder Structure for Code Readability
Overview
First of all, we need to generate the folder structure that the code will be able to read. The folder and subfolder structure is as follows:

Main Folder
Animal 1
Subfolders
Description: All sessions belonging to that animal.
Naming Convention: Each folder name must follow the structure: month_day_year_test.
Example: 7_6_2024_FR1
Inside Each Subfolder:
Session Recordings: There will be as many folders as there are calcium imaging videos recorded during that session.
Naming Convention for Recording Folders: Each folder must be named using the format H(hour)_M(minute)_S(second).
Example: H14_M53_S33
Additional File: Inside each recording folder, include the text file from the behavioral software.
Example: 2024-11-26_14h46m_Subject 6.txt
Other Files: Within each recording folder, there will also be the ms file and a CSV file named TimeStamps.csv.
Integrating the Folder Structure into Your Code
Once the folder structure is set up, insert each of the subfolders of the main folder into the base_path variable in your code. For example:

base_paths = {...
        'C:\Users\OneDrive\Documentos\Andero\Addiction\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_25_2024_FR1',...
        'C:\Users\OneDrive\Documentos\Andero\Addiction\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_26_2024_FR1',...
        'C:\Users\OneDrive\Documentos\Andero\Addiction\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_27_2024_FR1',...
        'C:\Users\OneDrive\Documentos\Andero\Addiction\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_28_2024_FR1',...
        'C:\Users\OneDrive\Documentos\Andero\Addiction\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\11_29_2024_FR5',...
        C:\Users\OneDrive\Documentos\Andero\Addiction\Nuevos animales noviembre\Carpetas ordenadas completas\Animal 13\12_02_2024_FR5'...
       
    };
