import os
import glob
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# Passo 1: Encontrar todos os arquivos com prefixo 'rq' e extensão '.txt'
arquivos = glob.glob("rq*.txt")

# Dicionário para armazenar as referências por arquivo
referencias_por_arquivo = {}

# Dicionário para armazenar as referências por amostra
referencias_por_amostra = {}

# Passo 2: Ler os arquivos e armazenar as referências
for arquivo in arquivos:
    with open(arquivo, 'r', encoding='utf-8') as f:
        referencias = {linha.strip() for linha in f if linha.strip()}  # Remove linhas em branco
        key = arquivo.split('.')[0].upper()
        referencias_por_arquivo[key] = referencias
        for referencia in referencias:
            referencias_por_amostra[referencia] = referencias_por_amostra.get(referencia, 0) + 1

# Passo 3: Construir o conjunto completo de todas as referências
todas_referencias = sorted(set().union(*referencias_por_arquivo.values()))
# todas_referencias = []
todas_referencias = [ (key, value) for key, value in referencias_por_amostra.items() ]
todas_referencias = sorted(todas_referencias, key=lambda x: (x[1], int(x[0][-4:])), reverse=False)
todas_referencias = [ key for key, value in todas_referencias ]

# Passo 4: Construir a matriz de presença (referência x arquivo)
df = pd.DataFrame(0, index=todas_referencias, columns=sorted(referencias_por_arquivo.keys(), key= lambda x: int(x.split('RQ')[1])) )

for arquivo, referencias in referencias_por_arquivo.items():
    for ref in referencias:
        df.at[ref, arquivo] = 1

# Passo 5: Gerar o heatmap com seaborn# Passo 4: Calcular tamanho da figura dinamicamente
altura_por_linha = 0.25    # ajuste conforme preferir
largura_por_coluna = 0.5   # ajuste conforme preferir
n_linhas = len(df.index)
n_colunas = len(df.columns)
altura = max(4, n_linhas * altura_por_linha)
largura = max(6, n_colunas * largura_por_coluna)

#fig, ax = plt.subplots(figsize=(largura, altura))
#sns.heatmap(df, cmap="Blues", cbar=True, linewidths=.1, linecolor='gray')

fig, ax = plt.subplots(figsize=(largura, altura))
sns.heatmap(df, cmap=sns.color_palette(["#ffffff", "#1f77b4"]), cbar=False, 
            linewidths=.1, linecolor='gray', vmin=0, vmax=1, square=False)


# Passo 5: Ajustar rótulos
# Eixo X (arquivos) rotacionados se necessário
ax.set_xticklabels(ax.get_xticklabels(), rotation=90, ha='center', fontsize=10)
# Eixo Y (referências) possivelmente diminuir fonte
ax.set_yticklabels(ax.get_yticklabels(), rotation=0, fontsize=6)

# plt.title('Heatmap of articles by research question')
plt.xlabel('Research Questions')
plt.ylabel('Articles')
plt.tight_layout()
plt.show()
