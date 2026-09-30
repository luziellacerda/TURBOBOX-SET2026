# Tutorial completo do Turborama 1.0 Genesis

Este guia permite baixar, compilar, instalar em cartão e recuperar a versão estável `v1.0.0` do Turborama. Destina-se ao proprietário e a quem assumir a manutenção. A regra principal é preservar o cartão funcional e o DTB correto antes de experimentar outra imagem.

A versão estável foi solicitada após relato de funcionamento em testes pelo responsável em 30/09/2026. O modelo comercial, a RAM real, a versão exibida pelo aparelho e a lista de testes não foram informados. Consulte os limites e as evidências nas [notas da versão](releases/v1.0.0.md).

## Baixar a imagem pronta

A [release v1.0.0](https://github.com/luziellacerda/TURBOBOX-SET2026/releases/tag/v1.0.0) reúne a imagem Generic, seu SHA256 e a documentação. O download automático de código-fonte do GitHub não é uma imagem inicializável.

Imagem de referência:

```text
Turborama-Amlogic-ng.aarch64-1.0-Genesis_devel_20260930083340-Generic.img.gz
```

Baixe também o arquivo de mesmo nome terminado em `.sha256`. No diretório que contém os dois arquivos:

```bash
sha256sum -c Turborama-Amlogic-ng.aarch64-1.0-Genesis_devel_20260930083340-Generic.img.gz.sha256
```

O resultado deve ser `OK`. O checksum detecta alterações no download; não comprova compatibilidade com o equipamento. O sufixo `devel` pertence ao binário original e foi mantido para não substituir a imagem ao promovê-la a estável.

## Preparar o computador de compilação

O ambiente utilizado foi Ubuntu 24.04.4 LTS x86_64, Xeon E5-2680 v4, 28 CPUs lógicas, aproximadamente 46 GiB de RAM e 11 GiB de swap. O código e os caches ficaram em um volume ext4 montado em `/mnt/DADOS`. Esses números descrevem o servidor, não requisitos mínimos certificados.

Use um disco Linux com espaço para fontes, toolchain, objetos e imagens. Reserve várias centenas de gigabytes para trabalhar com folga; o consumo aumenta ao manter múltiplas versões. Evite compilar na partição FAT do cartão de boot. Confira espaço, memória e montagem:

```bash
df -h .
free -h
findmnt -T .
```

Em Ubuntu, esta lista inicial cobre as ferramentas do verificador do repositório e as usadas neste guia. O próprio build informa dependências adicionais que faltarem:

```bash
sudo apt-get update
sudo apt-get install git openssh-client ca-certificates curl wget \
  bash bc build-essential gawk gperf patch patchutils diffutils \
  bzip2 gzip xz-utils zstd lzop zip unzip tar file perl \
  libncurses-dev libjson-perl libxml-parser-perl libparse-yapp-perl \
  xfonts-utils xsltproc default-jre-headless python3 golang-go \
  cpio squashfs-tools dosfstools mtools xmlstarlet gettext
```

O uso de `sudo` acima é para instalar ferramentas no computador. Não execute `make image` como root. A lista de referência do projeto está em [scripts/checkdeps](../scripts/checkdeps); ela pode solicitar instalação de pacotes ausentes.

## Obter a base estável

Para uma máquina nova, escolha antes um diretório de trabalho gravável. Exemplo, caso `/mnt/DADOS` já esteja montado e gravável:

```bash
cd /mnt/DADOS
git clone https://github.com/luziellacerda/TURBOBOX-SET2026.git
cd TURBOBOX-SET2026
git fetch origin --tags
git checkout --detach v1.0.0
git status --short --branch
git rev-parse HEAD
```

Para um clone existente, entre na raiz dele e confira `git status` antes de trocar de versão. Preserve alterações locais em uma branch/commit próprio. Não use comandos de limpeza ou descarte para forçar a troca.

A tag é o ponto de recuperação imutável. A branch `stable` aponta para a linha estável publicada; `main` e `turborama-1.0` podem receber mudanças. Para desenvolver sem mexer na referência estável:

```bash
git switch -c desenvolvimento/minha-alteracao v1.0.0
```

## Compilar em modo normal

Execute na raiz do clone:

```bash
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64 DISTRO=Turborama \
  THREADCOUNT=3 CONCURRENCY_MAKE_LEVEL=4 CONCURRENCY_LOAD=16 make image
```

Os três primeiros parâmetros selecionam a família, o dispositivo de build e a arquitetura. `DISTRO=Turborama` seleciona a distribuição. `THREADCOUNT=3` limita pacotes simultâneos, `CONCURRENCY_MAKE_LEVEL=4` limita o paralelismo de cada make e `CONCURRENCY_LOAD=16` controla o limite de carga usado pelo build. Esses limites foram usados no servidor; não significam que toda etapa terá exatamente essa quantidade de processos.

Para preservar um log e receber o código real de falha da compilação, use Bash:

```bash
set -o pipefail
build_log="turborama-build-$(date +%Y%m%d-%H%M%S).log"
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64 DISTRO=Turborama \
  THREADCOUNT=3 CONCURRENCY_MAKE_LEVEL=4 CONCURRENCY_LOAD=16 \
  DISABLE_COLORS=yes make image 2>&1 | tee "$build_log"
```

Não execute dois builds no mesmo clone ao mesmo tempo. Se uma execução for interrompida, verifique que terminou e repita o comando; o cache permite retomar etapas já concluídas. Não apague `sources/` e `build.*/` como primeira tentativa de corrigir lentidão. O download inicial, a criação da toolchain, compressão e acesso a muitos arquivos pequenos podem dominar o tempo total.

Uma compilação futura não é garantida como idêntica byte a byte: timestamps, ambiente e disponibilidade das fontes externas influenciam o resultado. Para recuperar exatamente o binário arquivado, baixe a release e confira o checksum.

## Localizar os resultados

Os arquivos ficam em `target/`. A pasta não é versionada no Git.

| Arquivo | Finalidade |
| --- | --- |
| `*-Generic.img.gz` | Imagem de disco comprimida para instalação nova em equipamentos Generic compatíveis |
| `*-Odroid_*.img.gz` e outras placas | Imagens específicas de placa, sem homologação automática por existir um build |
| `*.tar` | Pacote do sistema para manutenção/atualização compatível, não uma imagem de cartão |
| `*.system` | Sistema de arquivos SquashFS, chamado `SYSTEM` no boot |
| `*.kernel` | Kernel e ramdisk empacotados para esta família |
| `*.sha256` | Integridade do respectivo artefato |

Para conferir checksums gerados, dentro de `target/`:

```bash
for checksum in ./*.sha256; do
  test -f "$checksum" || continue
  sha256sum -c "$checksum" || exit 1
done
```

Nunca escolha uma imagem somente pela data mais recente. Confira família, arquitetura, placa, commit e DTB.

## Verificar o código e a imagem

Na raiz do clone:

```bash
python3 -m unittest discover -s tests -p 'test_turborama_*.py' -v
```

Na publicação inicial, os 23 testes passaram. São testes de contratos e comportamento local; não executam todos os emuladores no equipamento.

Para inspecionar a identificação sem montar nem executar o sistema ARM, substitua o caminho pelo artefato escolhido:

```bash
unsquashfs -cat target/ARQUIVO.system etc/os-release
```

Para auditoria completa do conteúdo extraído:

```bash
audit_dir=$(mktemp -d)
unsquashfs -no-progress -processors 2 -d "$audit_dir/system" target/ARQUIVO.system
python3 tools/audit-turborama-rootfs.py "$audit_dir/system" \
  --disk target/ARQUIVO-Generic.img.gz
```

Os nomes `ARQUIVO` são exemplos e devem ser substituídos. O auditor não executa o sistema extraído. `--initramfs /caminho/extraido` acrescenta a validação do ramdisk, cuja extração está no handoff. Se a imagem veio de outro clone, `--build-root /caminho/original` deve indicar exatamente o diretório em que ela foi compilada; isso classifica metadados de compilação, não libera nomes antigos de execução.

O arquivo `usr/cache/shadow` é extraído com modo `000`. Caso apareça `PermissionError`, em uma cópia temporária privada criada por você é possível liberar somente sua leitura e repetir a auditoria:

```bash
chmod u+r "$audit_dir/system/usr/cache/shadow"
python3 tools/audit-turborama-rootfs.py "$audit_dir/system" \
  --disk target/ARQUIVO-Generic.img.gz
chmod 000 "$audit_dir/system/usr/cache/shadow"
```

Não faça isso no aparelho, no cartão, na imagem de produção ou em diretório compartilhado. Não publique o conteúdo de `shadow`. Se a auditoria apontar problemas, guarde o relatório e investigue: não substitua textos diretamente nos binários.

## Instalar no cartão com segurança

1. Guarde o cartão que já funciona. Use outro cartão para testar a release ou uma recompilação.
2. Faça backup de configurações, saves, BIOS, jogos e DTB antes de qualquer gravação.
3. Baixe a imagem correta e valide SHA256.
4. Use uma ferramenta de gravação de imagem de disco. Se ela não aceitar `.img.gz`, descompacte uma cópia para `.img`.
5. Confira modelo e capacidade do cartão de destino. A gravação da imagem apaga o conteúdo do dispositivo selecionado; não escolha o disco do computador.
6. Após a gravação, reconecte o cartão e abra a partição `TURBORAMA`.
7. Para a imagem Generic que usa DTB externo, copie o DTB compatível para a raiz com o nome exato `dtb.img`.
8. Sincronize e ejete com segurança antes de remover. Faça o primeiro boot com alimentação estável e aguarde eventuais reinicializações de preparação do armazenamento.

Não formate separadamente `TURBORAMA` ou `STORAGE` depois de gravar a imagem. A partição inicial de dados pode ser pequena antes da preparação no primeiro boot. Não instale em eMMC sem um procedimento de recuperação específico para o aparelho.

## Escolher e preservar o DTB

O DTB descreve o hardware para o kernel. SoC, RAM, placa e periféricos importam; um nome parecido não garante compatibilidade.

O arquivo fornecido pelo responsável e copiado para o cartão antes do relato de teste tem estes dados:

```text
Nome: dtb.img
Tamanho: 86439 bytes
Identificador interno: sc2_s905x4_2g
SHA256: 38e8323c401e4f0bbd22ae2f464349bd770408ef117b02ab5cb3f5bbd1878cfb
```

Seu conteúdo é idêntico ao `sc2_s905x4_2g.dtb` incluído no sistema compilado. O identificador sugere S905X4 e configuração de 2 GB, mas não comprova o modelo comercial ou a RAM física do aparelho do responsável. Não use esse DTB indiscriminadamente em outros equipamentos.

Para copiar um arquivo já confirmado para o seu aparelho no Ubuntu, ajustando os caminhos quando necessário:

```bash
set -e
test -f '/home/lz-servidor/Vídeos/dtb.img'
mountpoint -q /media/lz-servidor/TURBORAMA || exit 1
findmnt --mountpoint /media/lz-servidor/TURBORAMA
if test -e /media/lz-servidor/TURBORAMA/dtb.img; then
  dtb_backup=$(mktemp -d)
  cp -- /media/lz-servidor/TURBORAMA/dtb.img "$dtb_backup/dtb.img"
  printf 'Backup do DTB anterior: %s\n' "$dtb_backup/dtb.img"
fi
cp -- '/home/lz-servidor/Vídeos/dtb.img' /media/lz-servidor/TURBORAMA/dtb.img
sync -f /media/lz-servidor/TURBORAMA/dtb.img
cmp -- '/home/lz-servidor/Vídeos/dtb.img' /media/lz-servidor/TURBORAMA/dtb.img
```

Esse é o caminho utilizado no servidor original, não um caminho obrigatório em outros computadores. Copie o backup temporário para armazenamento permanente. Não altere `kernel.img`, `SYSTEM`, `cfgload`, `aml_autoscript` nem rótulos de partição para resolver um problema de colagem.

## Conferir o primeiro boot

No próprio Turborama, via terminal ou SSH quando disponível:

```bash
cat /etc/os-release
cat /turborama_arch
cat /usr/config/TURBORAMA_VERSION
systemctl get-default
systemctl --failed --no-pager
systemctl status emustation.service --no-pager
df -h /flash /storage /storage/roms
```

O target padrão esperado é `turborama.target`. Verifique interface, controles, HDMI, áudio, rede e jogos legalmente disponíveis para teste, além de reiniciar, desligar, salvar e retornar de jogos. Registre modelo, RAM, DTB, versão/BUILD_ID e resultados; não marque itens não testados como aprovados.

A configuração do código define senha inicial de root `turborama`. Se habilitar acesso remoto, troque-a com `passwd`, mantenha o equipamento em rede confiável e não exponha SSH ou compartilhamentos diretamente à Internet.

## Recuperar quando algo não funcionar

| Sintoma | Verificação segura |
| --- | --- |
| Não inicializa ou para no logo | Volte ao cartão funcional; confira checksum, família da imagem, DTB, alimentação e leitor |
| Tela preta após iniciar | Confira HDMI/resolução, frontend e serviço Mali; não renomeie unidades systemd por tentativa |
| Não consegue copiar para a raiz | Confira `findmnt`, `df -h` e proprietário do ponto montado; procure montagem somente leitura e erros de I/O |
| Cartão desconecta ou há erro FAT | Pare novas gravações, preserve os dados e verifique cartão/leitor; reparo só com a partição desmontada e o dispositivo exato identificado |
| Build muito lento | Confira memória, swap, espaço, carga e a etapa no log; reduza paralelismo antes de apagar caches |
| Atualização não aparece | O catálogo permanece desativado nesta publicação; isso é intencional |

Para diagnóstico local no aparelho:

```bash
journalctl -b -u libmali.service -u turborama-autostart.service -u emustation.service --no-pager
journalctl -b -p err --no-pager
dmesg | tail -80
```

Revise os logs antes de compartilhá-los. O utilitário `turboramalogs.sh` também pode enviar dados para um serviço externo; não o use supondo que a coleta é exclusivamente local.

## Atualizações e cópias de segurança

A release estável no GitHub não habilita atualização automática. O catálogo `settings/TURBORAMA_update` continua sem versões anunciadas. Migração de instalações com identidade anterior e atualização em eMMC não foram homologadas.

Guarde fora deste computador a imagem `.img.gz`, o `.sha256`, o DTB usado, as configurações e os saves. Um clone do Git sozinho não contém `target/`, fontes baixadas ou objetos de compilação. Consulte o [handoff](HANDOFF-TURBORAMA.md) para preservar também fontes, dependências e o procedimento de retomada.
