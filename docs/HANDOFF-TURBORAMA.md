# Handoff técnico do Turborama 1.0 Genesis

Este documento permite retomar o projeto sem depender do histórico de conversa. O ponto de recuperação é a tag `v1.0.0` do repositório [TURBOBOX-SET2026](https://github.com/luziellacerda/TURBOBOX-SET2026). Leia também o [tutorial](TUTORIAL-TURBORAMA.md), as [notas de publicação](releases/v1.0.0.md) e o [manifesto](releases/v1.0.0.json).

## Estado da entrega

Em 30/09/2026, o responsável relatou que a compilação está funcionando em testes e solicitou sua promoção a estável. A promoção preserva o sistema compilado; as alterações desta entrega são documentação e referências Git, sem mudanças em boot, serviços ou dependências.

- Base do código executável: `10bba5ef28aed80d67792015b0a05c4439962efe`.
- Versão do sistema arquivado: `1.0-Genesis_devel_20260930083340`.
- Tag pública: `v1.0.0`; a tag inclui documentação posterior ao commit do binário.
- Projeto/dispositivo/arquitetura/distribuição: `Amlogic-ce` / `Amlogic-ng` / `aarch64` / `Turborama`.
- Imagem publicada: Generic, com checksum original e sem recompressão ou troca de nome.
- Atualizador automático: catálogo vazio, preservado.

O `BUILD_ID` do binário não coincide necessariamente com o commit da tag que adiciona estes documentos. Essa diferença é intencional e está registrada. Não recompile só para fazer os hashes coincidirem, pois isso geraria outro artefato.

## O que o teste no aparelho comprova

Há relato do responsável de funcionamento em testes. Não foram fornecidos modelo comercial, RAM física, saída de `/etc/os-release`, tempo de uso ou checklist de periféricos. Portanto, não há associação independente comprovada entre o cartão testado e o checksum da imagem arquivada mais recente. Ela foi verificada como uma compilação do mesmo commit de código da base publicada.

O DTB entregue pelo responsável foi copiado e conferido antes desse relato. Ele tem identificador `sc2_s905x4_2g`, 86439 bytes e SHA256 `38e8323c401e4f0bbd22ae2f464349bd770408ef117b02ab5cb3f5bbd1878cfb`. É idêntico ao DTB de mesmo identificador incluído nesta compilação. Isso identifica o arquivo, não certifica todas as placas S905X4.

Antes de ampliar a homologação, registre modelo, SoC, RAM, mídia, DTB, BUILD_ID, vídeo, áudio, controles, rede, jogos, saves e reinicializações. Não anuncie outros modelos como testados por inferência.

## Contratos que não devem ser quebrados

| Área | Contrato atual | Risco de alteração isolada |
| --- | --- | --- |
| Boot | FAT com rótulo `TURBORAMA` | Bootloader/initramfs podem não localizar o sistema |
| Dados | Rótulo `STORAGE`, montado em `/storage` | Perda do acesso às configurações persistentes |
| Jogos | Rótulo `TURBOROMS`, uso em `/storage/roms` | Jogos e dados podem deixar de ser encontrados |
| Configuração | `/turborama` aponta para `/storage/.config/turborama` | Quebra de comandos, launchers e bibliotecas |
| Identidade | `/turborama_arch` e `/usr/config/TURBORAMA_VERSION` | Atualizador pode selecionar pacote incorreto |
| Inicialização | `turborama.target` como target padrão | Interface pode não iniciar |
| Interface | `emustation.service` | Integrações existentes usam esse nome |
| Gráficos | `libmali.service` antes de autostart, frontend e RetroArch | Interface pode iniciar sem as bibliotecas corretas |
| Sixaxis | Template instanciado por udev, sem habilitar `sixaxis@.service` vazio | Falha de unidade na inicialização |
| Atualização | Arquivo da família correta, SHA256 e staging exclusivo | Atualização incompleta, incorreta ou sobrescrita |

Não faça substituição global de nomes em executáveis, firmware ou árvores de dispositivo. Preserve licenças, créditos e campos de compatibilidade `LIBREELEC_*`/`COREELEC_*`. O nome da interface EmulationStation e o serviço `emustation.service` não são nomes de distribuição a eliminar.

## Mapa do código

- `distributions/Turborama/options` e `version`: identidade, versão, rótulos, tamanho da partição e configurações de build.
- `projects/Amlogic-ce/devices/Amlogic-ng/`: kernel e opções da família.
- `packages/sx05re/turborama/`: scripts, serviços, configuração, splash e vídeo de abertura.
- `packages/sx05re/turborama/bin/updatecheck.sh`: seleção, download, checksum e staging de atualizações.
- `packages/sx05re/turborama-emulationstation/`: pin do frontend, configuração e temas.
- `packages/sx05re/tools/sysutils/turborama-sysutils/`: utilitários de configuração e serviço auxiliar.
- `packages/sysutils/busybox/scripts/init`: montagem e preparação no initramfs.
- `tests/test_turborama_*.py`: regressões de identidade, boot, atualização e scripts.
- `tools/audit-turborama-rootfs.py`: inspeção estática do sistema extraído e rótulos da imagem.

As correções anteriores à base estável incluem ordenação do Mali, Sixaxis por instância, Bluetooth em Python 3, segurança no atualizador, problemas de memória/hash/CHD/gêneros no frontend e consistência do marcador Java. Não as reverta ao atualizar forks.

## Dependências próprias fixadas

As receitas `package.mk` são a fonte de verdade. Estes são os pins na base publicada; não atualize branches de dependências implicitamente durante recuperação.

| Repositório na conta luziellacerda | Commit |
| --- | --- |
| `turborama-emulationstation` | `841d21909db2c8a1fe015bb838fd77695d77e730` |
| `es-theme-Turborama-crystal` | `7c2304f663d7a7e682efbb6aa1fbcde6f3d4b7bc` |
| `es-theme-Turborama-carbon` | `381e539bd1d7e86d87e2ba679e95ddca6888ddd2` |
| `turborama-32bit-libs` | `6f338555e4383c7a4919ad1776595a22e444f0fc` |
| `turborama-mount` | `583b1dd78da10793fcbf31f5da048f93cefe0dfd` |
| `turborama-jslisten` | `b7f85c2573baaa49580104fade2af96d34f3546b` |
| `gptokeyb` | `0ef26603fd55226937b089b4c64b1043d0cf7b0a` |
| `351Files` | `2fa3f9ff8e50fb9b897fbc667affabd4ece004e7` |
| `rs97-commander-sdl2` | `b83ef67f6e20bdd5af3276b5e6e8705109b400aa` |
| `sdljoytest` | `2de7e7fa14e11059eda7061caa95f2130e3ae68d` |
| `turborama-touchHLE` | `f8f21296b1bf2e5112db5e2ee36a683b7610d1ff` |

O frontend usa a branch `Turborama`, mas o build seleciona o commit fixado. Seu teste complementar, dentro do clone desse fork, é:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

Na entrega, os quatro testes passaram, incluindo verificações com sanitizadores de memória. Isso não equivale a executar todos os caminhos do frontend ARM.

## Encontrar o ambiente original

No servidor original, o usuário é `lz-servidor`; o disco ext4 está em `/mnt/DADOS`. O clone usa um nome histórico no disco. Para localizá-lo sem renomear diretórios que a toolchain utiliza:

```bash
for repo in /mnt/DADOS/*; do
  test -d "$repo/.git" || continue
  case "$(git -C "$repo" remote get-url origin 2>/dev/null)" in
    *luziellacerda/TURBOBOX-SET2026*) printf '%s\n' "$repo" ;;
  esac
done
```

Entre no caminho retornado. Os artefatos ficam em `target/`, o cache principal em `build.Turborama-Amlogic-ng.aarch64-1/`, e as fontes baixadas em `sources/`. Os clones de dependências ficam em `/mnt/DADOS/Turborama-deps/`. Alguns nomes locais históricos diferem dos nomes dos repositórios remotos; consulte `git remote -v` em cada clone.

Arquivos auxiliares locais existentes, que não fazem parte do clone Git:

- `/mnt/DADOS/turborama-build-resume.sh` e `/mnt/DADOS/turborama-image-verify.sh`.
- `/mnt/DADOS/turborama-image-build.log` e `/mnt/DADOS/turborama-image-verify.log`.
- `/home/lz-servidor/Vídeos/dtb.img`, origem do DTB usado nesta sessão.

Os scripts auxiliares contêm caminhos absolutos do servidor e não são portáveis. O script antigo de verificação pode reconstruir a imagem quando o HEAD difere do BUILD_ID. Não o execute para validar o binário congelado depois de adicionar documentação; use a auditoria somente de leitura descrita aqui.

Os logs antigos de 29/09 não comprovam, por si só, o build mais recente de 30/09. A auditoria antiga parou por permissão ao ler a cópia extraída de `shadow`; preserve esse histórico sem declarar sucesso retroativo. A validação desta publicação tem registro próprio nas notas da release.

## Extrair o initramfs para auditoria

Este procedimento é específico do cabeçalho Android v0 usado no kernel Amlogic-ng desta base. Execute na raiz do clone, com `ARQUIVO.kernel` substituído pelo artefato escolhido. Ele cria somente uma extração temporária:

```bash
set -euo pipefail
kernel=target/ARQUIVO.kernel
audit_dir=$(mktemp -d)
test "$(head -c 8 "$kernel")" = 'ANDROID!'
kernel_size=$(od -An -tu4 -j8 -N4 "$kernel" | tr -d ' ')
ramdisk_size=$(od -An -tu4 -j16 -N4 "$kernel" | tr -d ' ')
page_size=$(od -An -tu4 -j36 -N4 "$kernel" | tr -d ' ')
[[ "$page_size" == 2048 || "$page_size" == 4096 ]]
test "$kernel_size" -gt 0
test "$ramdisk_size" -gt 0
offset=$((page_size + ((kernel_size + page_size - 1) / page_size) * page_size))
dd if="$kernel" of="$audit_dir/ramdisk.cpio" bs=1M \
  iflag=skip_bytes,count_bytes skip="$offset" count="$ramdisk_size" status=none
mkdir "$audit_dir/initramfs"
(cd "$audit_dir/initramfs" && \
  cpio -id --quiet --no-absolute-filenames init platform_init functions < ../ramdisk.cpio)
printf 'Initramfs extraido: %s\n' "$audit_dir/initramfs"
```

Passe esse diretório com `--initramfs` para o auditor, junto da extração do `SYSTEM`. Se a assinatura ou o tamanho de página não coincidir, pare; não aplique offsets por tentativa a outro formato de kernel.

## Preservar uma cópia independente

GitHub não substitui uma cópia offline. Guarde em mídia independente:

1. Imagem Generic e `.sha256` da release, com verificação após a cópia.
2. DTB funcional e seu checksum, além da identificação do aparelho.
3. Bundle do código principal e dos forks necessários; confira se os commits fixados estão presentes.
4. `sources/` para diminuir dependência de downloads externos futuros.
5. Logs de build, manifesto e informações do ambiente.
6. Saves e configurações do aparelho, guardados de forma privada.

Exemplo para o Git principal, a partir da raiz do clone:

```bash
git fetch origin --tags
backup_dir=$(mktemp -d)
git bundle create "$backup_dir/TURBOBOX-SET2026.bundle" --all
git bundle verify "$backup_dir/TURBOBOX-SET2026.bundle"
printf 'Copie este arquivo para a midia de backup: %s\n' "$backup_dir/TURBOBOX-SET2026.bundle"
```

O bundle inclui objetos Git, não arquivos ignorados, credenciais, arquivos LFS externos nem caches de build. Para restaurar o principal:

```bash
git clone /CAMINHO/DO/BACKUP/TURBOBOX-SET2026.bundle TURBOBOX-SET2026
cd TURBOBOX-SET2026
git remote set-url origin https://github.com/luziellacerda/TURBOBOX-SET2026.git
git checkout --detach v1.0.0
```

Clones de forks e caches devem ser guardados separadamente. Um cache de toolchain pode conter caminhos absolutos, portanto não é portável entre diretórios arbitrários. Um build inteiramente offline ainda exige conferir todas as fontes transitivas; não foi certificado nesta entrega.

Não publique chaves SSH, tokens GitHub, senhas de Wi-Fi, arquivos de API ou dados pessoais. O arquivo opcional `packages/sx05re/turborama-emulationstation/api_keys.txt` é ignorado pelo Git; estava ausente ao verificar esta publicação.

## Fluxo para a próxima versão

1. Preserve a tag, os assets e o cartão funcional desta versão. Não mova `v1.0.0` nem substitua seus binários.
2. Crie uma branch a partir da tag e faça mudanças pequenas, com commits explicativos.
3. Mantenha os contratos de boot e os pins de dependências explícitos.
4. Execute os 23 testes e, se alterar o frontend, os testes do fork correspondente.
5. Compile, valide checksums, audite SYSTEM/initramfs/rótulos e registre o BUILD_ID real.
6. Teste em outro cartão no modelo exato, incluindo pelo menos boot frio, reboot, controle, áudio, jogo e save.
7. Publique outra tag e outro manifesto com evidências e limites; não rotule uma recompilação como o mesmo binário.
8. Só habilite o catálogo de atualização depois de testar migração, ordem de versões e correspondência exata entre tag, nome de `.tar` e checksum.

O atualizador monta URLs a partir da versão interna e espera uma release `v<versão>` com `Turborama-<dispositivo>.aarch64-<versão>.tar`. A tag documental `v1.0.0` não deve ser colocada cegamente no catálogo, pois não corresponde à versão interna do binário arquivado. Nesta entrega, o `.tar` e imagens de outras placas permanecem apenas como resultados locais; a distribuição pública inicial é a imagem Generic.

## Instrução de retomada para outro mantenedor

Leia este handoff e o tutorial. Confirme o estado Git e a tag `v1.0.0`; preserve mudanças não relacionadas. Use o manifesto para distinguir o commit da documentação, o BUILD_ID do sistema e os hashes dos artefatos. Não altere boot, DTB, nomes de serviços, rótulos ou atualizador sem testar o conjunto. Não formate mídia nem instale em eMMC como tentativa de diagnóstico. Registre novas evidências e publique cada mudança de sistema como uma nova versão verificável.
