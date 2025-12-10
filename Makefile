# Makefile pour Space Breaker (DOSBox - Fichier .COM)

# Outils
ASM = nasm

# Flags
# -f bin : Format binaire brut pour DOS .COM
# -I include/ : Chemin d'inclusion
ASMFLAGS = -f bin -I include/

# Fichiers
SRC = src/main.asm
OUT = game.com

# Règles
all: $(OUT)

$(OUT): $(SRC) src/render.asm src/data.asm include/constants.inc
	$(ASM) $(ASMFLAGS) $(SRC) -o $(OUT)

clean:
	rm -f $(OUT)

re: clean all
