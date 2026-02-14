#!/bin/bash
if [ -z "$1" ]; then
    echo "Uso: ./add_knowledge.sh 'Minha instrução para a IA'"
    exit 1
fi
echo "$1" > aiops/brain/memo_$(date +%s).md
docker exec -it ai-agent python3 reindex_brain.py
echo "✅ IA atualizada!"
