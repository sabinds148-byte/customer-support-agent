# Local Development Guide

Run the Customer Support Agent locally using WSL2 Ubuntu, Linux, or macOS.

## 1. Run the setup script

```bash
sudo chmod +x deployment/local/setup.sh
sudo deployment/local/setup.sh
```

## 2. Configure your OpenAI API key

```bash
cd ~/customer-support-agent/backend
cp .env.example .env
nano .env
```

Add:

```text
OPENAI_API_KEY=sk-your-actual-key-here
```

## 3. Activate the virtual environment

```bash
cd ~/customer-support-agent
source venv/bin/activate
```

## 4. Start the backend

```bash
cd ~/customer-support-agent/backend
uvicorn app.main:app --reload
```

## 5. Open the frontend application

After starting the backend, open your browser and go to:

```text
http://localhost:8000/
```

## 6. Verify

- Health: http://localhost:8000/health
- API Docs: http://localhost:8000/docs

## Running again later

```bash
cd ~/customer-support-agent/backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

## Cleanup

Remove everything the setup script and app runtime created, to start fresh:

```bash
cd ~/customer-support-agent

# Remove the Python virtual environment
rm -rf venv

# Remove the vector store (regenerated on next run)
rm -rf backend/knowledge_base

# Remove logs and cached bytecode
rm -f backend/agent.log
find . -type d -name "__pycache__" -exec rm -rf {} +

# Optional: remove your local API key config
rm -f backend/.env
```
