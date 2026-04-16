# Smart Librarian

Aplicatie de recomandare de carti construita cu Streamlit, OpenAI si ChromaDB.
Proiectul cauta semantic in baza locala de carti, recomanda un titlu relevant, apoi cere rezumatul complet prin tool calling. Optional, poate genera si o imagine inspirata de cartea recomandata.

## Functionalitati

- interfata web simpla cu Streamlit
- cautare semantica peste rezumate de carti folosind embeddings OpenAI
- stocare vectoriala locala cu ChromaDB
- recomandari de carti in limba romana
- tool calling pentru extragerea rezumatului complet
- generare optionala de imagine pentru cartea recomandata

## Tehnologii folosite

- Python
- Streamlit
- OpenAI API
- ChromaDB
- pytest

## Cerinte

Inainte sa rulezi aplicatia, asigura-te ca ai instalate:

- Python 3.10 sau mai nou
- pip
- o cheie valida OpenAI API

## Instalare

### 1. Cloneaza repository-ul

```bash
git clone <repo-url>
cd "Python - Smart Librarian Project"
```

### 2. Creeaza un mediu virtual

Pe Windows PowerShell:

```powershell
python -m venv venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\venv\Scripts\Activate.ps1
```

Pe macOS sau Linux:

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Instaleaza dependintele

```bash
pip install -r requirements.txt
```

## Configurare mediu

Creeaza un fisier `.env` in radacina proiectului cu urmatorul continut:

```env
OPENAI_API_KEY=your_openai_api_key
OPENAI_EMBEDDING_MODEL=text-embedding-3-small
OPENAI_CHAT_MODEL=gpt-4o-mini
APP_DEFAULT_LANGUAGE=ro
```

### Variabile necesare

- `OPENAI_API_KEY` - cheia ta pentru API-ul OpenAI
- `OPENAI_EMBEDDING_MODEL` - modelul folosit pentru embeddings
- `OPENAI_CHAT_MODEL` - modelul folosit pentru conversatie si tool calling

### Variabila optionala

- `APP_DEFAULT_LANGUAGE` - implicit este `ro`

## Build pentru baza vectoriala

Aplicatia foloseste un index ChromaDB local in folderul `chroma_db`. Daca vrei sa reconstruiesti indexul din fisierul cu rezumate, ruleaza:

```bash
python -m src.services.vector_store
```

Comanda:

- incarca datele din `src/data/book_summaries.json`
- genereaza embeddings prin OpenAI
- sterge documentele vechi din colectia `books`
- recreeaza indexul local in `chroma_db`

Daca folderul `chroma_db` exista deja si contine date corecte, poti sari peste acest pas.

## Rulare aplicatie

Din radacina proiectului, cu mediul virtual activ:

```bash
streamlit run streamlit_app.py
```

Dupa pornire, Streamlit va afisa in terminal un URL local, de obicei:

```text
http://localhost:8501
```

Deschide acel URL in browser pentru a folosi aplicatia.

## Cum folosesti aplicatia

1. Scrii in chat ce tip de carte cauti.
2. Aplicatia cauta semantic cele mai relevante titluri.
3. Modelul alege o singura recomandare.
4. Se apeleaza tool-ul intern pentru rezumatul complet.
5. Optional, poti genera si o imagine inspirata de carte.

Exemple de intrebari:

- `Vreau o carte despre libertate si control social`
- `Ce-mi recomanzi daca iubesc povestile fantastice?`
- `Vreau o carte despre razboi si supravietuire`

## Rulare teste

Pentru a rula testele unitare:

```bash
pytest
```

## Structura proiectului

```text
.
|-- streamlit_app.py
|-- requirments.txt
|-- chroma_db/
|-- src/
|   |-- config.py
|   |-- clients/
|   |-- data/
|   |-- services/
|   `-- utils/
`-- tests/
```

## Arhitectura clean folosita

Proiectul urmareste o varianta simplificata de clean architecture, in care responsabilitatile sunt separate clar, astfel incat codul sa fie mai usor de inteles, testat si extins.

### 1. Presentation layer

Fisierul `streamlit_app.py` joaca rolul de strat de prezentare.
Acesta se ocupa doar de:

- afisarea interfetei
- citirea inputului utilizatorului
- afisarea raspunsului
- controlul optiunilor din UI, cum ar fi debug sau generarea imaginii

Ideea principala este ca logica de business nu sta in interfata.

### 2. Application / service layer

In folderul `src/services/` se afla fluxurile principale ale aplicatiei:

- `chatbot.py` coordoneaza flow-ul principal: guardrails, clasificare intentie, RAG, tool calling si raspuns final
- `rag.py` se ocupa de cautarea semantica in vector store
- `vector_store.py` construieste si reconstruieste indexul ChromaDB
- `image_generator.py` izoleaza logica pentru generarea imaginilor

Acest strat contine comportamentul aplicatiei si orchestreaza colaborarea dintre componente.

### 3. Infrastructure layer

Dependintele externe sunt izolate in zone dedicate:

- `src/clients/openai_client.py` gestioneaza conectarea la OpenAI
- `src/config.py` centralizeaza configurarea prin variabile de mediu
- ChromaDB este folosit ca persistenta locala pentru embeddings in folderul `chroma_db`
- `src/data/book_summaries.json` reprezinta sursa locala de date pentru carti

Aceasta separare reduce cuplarea dintre logica aplicatiei si furnizorii externi.

### 4. Utilities / supporting logic

In folderul `src/utils/` se afla componente suport:

- `tools.py` expune tool-ul care returneaza rezumatul complet pentru un titlu
- `conversation_control.py` contine validari, reguli de conversatie si clasificarea intentiei

Aceste module sustin logica principala fara sa incarce inutil stratul de prezentare sau serviciile.

### Beneficiile acestei structuri

- fiecare fisier are un rol clar
- logica de business poate fi testata independent de UI
- dependintele externe sunt mai usor de inlocuit sau mock-uit in teste
- proiectul poate creste mai usor fara sa devina haotic

### Observatie importanta

Arhitectura folosita aici este o forma practica si usoara de clean architecture, potrivita pentru un proiect de dimensiune mica spre medie. Nu este o implementare stricta, cu entitati, use cases si adaptoare separate la nivel enterprise, dar respecta ideea centrala: separarea responsabilitatilor si izolarea dependintelor.

## Probleme frecvente

### Eroare legata de `.env`

Daca lipsesc variabilele de mediu, aplicatia va ridica erori de forma:

```text
OPENAI_API_KEY is not set in .env
```

Verifica existenta fisierului `.env` si valorile configurate.

### Aplicatia nu gaseste rezultate relevante

Reconstruieste indexul vectorial:

```bash
python -m src.services.vector_store
```

### Streamlit nu porneste

Asigura-te ca:

- mediul virtual este activ
- dependintele sunt instalate
- comanda este rulata din radacina proiectului

## Comenzi rapide

```bash
pip install -r requirments.txt
python -m src.services.vector_store
streamlit run streamlit_app.py
pytest
```
