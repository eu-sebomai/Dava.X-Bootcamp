import streamlit as st

from src.services import run_chatbot
from src.services.image_generator import generate_book_image


st.set_page_config(
    page_title="Smart Librarian",
    page_icon="👨‍🏫",
    layout="wide",
)

st.title("👨‍🏫 Smart Librarian")
st.caption("Recomandari de cartii cu RAG si OpenAI Tool Calling folosind ChromaDB")

with st.sidebar:
    st.header("Despre aplicație")
    st.write(
        "Aplicația caută semantic în baza de cărți, recomandă o carte, "
        "apoi cere rezumatul complet prin tool calling."
    )
    show_debug = st.toggle("Arată rezultate RAG", value=False)

    st.markdown("---")

    st.write("Exemple de întrebări:")
    st.write("- Vreau o carte despre libertate și control social")
    st.write("- Ce-mi recomanzi dacă iubesc poveștile fantastice?")
    st.write("- Vreau o carte despre război și supraviețuire")
    
    st.markdown("---")

    generate_image = st.toggle("Genereaza imagine pentru cartea recomandata", value=False)

if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

for item in st.session_state.chat_history:
    with st.chat_message(item["role"]):
        st.markdown(item["content"])

prompt = st.chat_input("Scrie ce fel de carte cauți...")

if prompt:
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            try:
                result = run_chatbot(
                    user_query=prompt,
                    chat_history=st.session_state.chat_history,
                )
                answer = result["answer"]

                st.markdown(answer)

                if result["selected_title"]:
                    st.success(f"Titlu recomandat: {result['selected_title']}")
                
                if generate_image and result["selected_title"]:
                    try:
                        image_result = generate_book_image(
                            title=result["selected_title"],
                            summary=result["summary"],
                        )

                        st.markdown("### Ilustratie inspirata de carte")
                        st.image(image_result["image_bytes"], width=450)

                    except Exception as error:
                        st.warning(f"Nu am putut genera imaginea: {error}")

                if show_debug and result["results"]:
                    st.markdown("### Rezultate RAG")
                    docs = result["results"].get("documents", [[]])[0]
                    metas = result["results"].get("metadatas", [[]])[0]
                    distances = result["results"].get("distances", [[]])[0]

                    for idx, doc in enumerate(docs):
                        meta = metas[idx] if idx < len(metas) else {}
                        distance = distances[idx] if idx < len(distances) else None
                        title = meta.get("title", "Necunoscut")
                        author = meta.get("author", "Necunoscut")
                        themes = meta.get("themes", "")

                        with st.expander(f"#{idx + 1} - {title}"):
                            st.write(f"**Autor:** {author}")
                            st.write(f"**Teme:** {themes}")
                            if distance is not None:
                                st.write(f"**Distanță semantică:** {distance}")
                            st.write("**Conținut indexat:**")
                            st.code(doc, language="markdown")

                st.session_state.chat_history.append(
                    {"role": "user", "content": prompt}
                )
                st.session_state.chat_history.append(
                    {"role": "assistant", "content": answer}
                )

            except Exception as error:
                error_message = f"A apărut o eroare: {error}"
                st.error(error_message)
                st.session_state.chat_history.append(
                    {"role": "user", "content": prompt}
                )
                st.session_state.chat_history.append(
                    {"role": "assistant", "content": error_message}
                )