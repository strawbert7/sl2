import os
import streamlit as st
import google.generativeai as genai

# --- Read API key (tries Streamlit secrets first, then env var)
API_KEY = st.secrets.get("GEMINI_API_KEY", os.getenv("GEMINI_API_KEY"))
if not API_KEY:
    st.error("⚠️ Missing GEMINI_API_KEY. Add it to .streamlit/secrets.toml or environment variables.")
    st.stop()

genai.configure(api_key=API_KEY)

# --- UI
st.set_page_config(page_title="Gemini + Streamlit", page_icon="✨", layout="centered")
st.title("✨ Gemini + Streamlit (AI Studio API Key)")

# Model selector (you can adjust list to what your key supports)
MODEL_OPTIONS = [
    "gemini-1.5-flash",
    "gemini-1.5-pro",
    "gemini-1.0-pro",
]
model_name = st.selectbox("Model", MODEL_OPTIONS, index=0)

# System/behavior prompt (optional)
system_prompt = st.text_area(
    "System prompt (optional)",
    value="You are a helpful assistant.",
    help="Sets overall behavior for the assistant."
)

# Chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display history
for m in st.session_state.messages:
    with st.chat_message(m["role"]):
        st.markdown(m["content"])

# User input
user_msg = st.chat_input("Ask me anything...")
if user_msg:
    st.session_state.messages.append({"role": "user", "content": user_msg})
    with st.chat_message("user"):
        st.markdown(user_msg)

    # Build contents (system + history)
    # The Gemini Python SDK accepts a list of dicts with "role" and "parts"
    contents = []
    if system_prompt.strip():
        contents.append({"role": "user", "parts": [f"[System instruction]\n{system_prompt}"]})
    for m in st.session_state.messages:
        contents.append({"role": m["role"], "parts": [m["content"]]})

    # Generate
    with st.chat_message("assistant"):
        placeholder = st.empty()
        try:
            model = genai.GenerativeModel(model_name)
            # Stream tokens for a responsive UI
            stream = model.generate_content(contents, stream=True)
            full_text = ""
            for chunk in stream:
                if chunk.text:
                    full_text += chunk.text
                    placeholder.markdown(full_text)
            st.session_state.messages.append({"role": "assistant", "content": full_text})
        except Exception as e:
            st.error(f"Error: {e}")
