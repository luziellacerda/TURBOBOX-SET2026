# Turborama

Turborama é um sistema operacional de jogos retro para dispositivos Amlogic, com interface EmulationStation, RetroArch, emuladores standalone e suporte a instalação em cartão SD, USB e eMMC compatível.

## Versão

- Canal: estável, tag `v1.0.0`, publicada em 30/09/2026
- Produto: Turborama
- Versão: 1.0
- Codinome: Genesis
- Arquitetura: aarch64
- Projeto: Amlogic-ce
- Dispositivo: Amlogic-ng

O responsável informou funcionamento em testes no aparelho em 30/09/2026. Esse relato não equivale a homologação de todos os modelos, periféricos ou instalação em eMMC. A imagem preserva sua identificação original `1.0-Genesis_devel_20260930083340`; não foi recompilada apenas para mudar o nome. O código de execução está baseado no commit `10bba5ef28aed80d67792015b0a05c4439962efe`.

## Downloads e documentação

- [Versão estável e imagem Generic](https://github.com/luziellacerda/TURBOBOX-SET2026/releases/tag/v1.0.0)
- [Tutorial completo de compilação e instalação](docs/TUTORIAL-TURBORAMA.md)
- [Handoff para manutenção e recuperação futura](docs/HANDOFF-TURBORAMA.md)
- [Notas e limites da versão estável](docs/releases/v1.0.0.md)
- [Manifesto com versões e checksums](docs/releases/v1.0.0.json)

## Compilação

```bash
git clone https://github.com/luziellacerda/TURBOBOX-SET2026.git
cd TURBOBOX-SET2026
git checkout --detach v1.0.0
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64 DISTRO=Turborama \
  THREADCOUNT=3 CONCURRENCY_MAKE_LEVEL=4 CONCURRENCY_LOAD=16 make image
```

Compile como usuário normal. A tag fixa a base estável; `turborama-1.0` é uma branch que pode avançar. Dependências, logs, verificação da imagem, DTB e recuperação estão no tutorial. Uma nova compilação terá outro timestamp e não promete o mesmo checksum do binário arquivado.

## Identidade do sistema

A distribuição, partição de boot, diretórios de configuração, comandos, serviços, logs, telas, hostname e arquivos gerados usam a identidade Turborama.

A partição de boot usa o rótulo `TURBORAMA`, os dados do sistema usam `STORAGE` e a partição de jogos usa `TURBOROMS`. As configurações ficam em `/storage/.config/turborama`, acessíveis pelo link `/turborama`. A inicialização usa `turborama.target`, com o frontend em `emustation.service`.

## Verificação local

```bash
python3 -m unittest discover -s tests -p 'test_turborama_*.py' -v
```

Os testes verificam configurações, versões, identidade de dispositivo, checksum de atualização, tratamento de teclas, contratos de inicialização e referências de identidade nos arquivos rastreados. A inspeção de texto preserva os créditos originais e não substitui a revisão de imagens e binários nem o teste de boot no hardware.

Para uma imagem `SYSTEM` extraída, a auditoria estrutural é somente de leitura e não executa os binários ARM:

```bash
python3 tools/audit-turborama-rootfs.py /caminho/para/system-extraido --initramfs /caminho/para/initramfs-extraido
```

Essa auditoria confere identidade, serviços habilitados, carregadores ELF, configurações e integração do atualizador. O argumento `--initramfs` é opcional. Use também `--disk /caminho/para/Generic.img.gz` para conferir os rótulos das partições de boot e dados, sem montar nem alterar a imagem.

A varredura do conteúdo extraído inclui nomes de arquivos, links e textos dentro dos binários. Créditos de autoria e caminhos de compilação são contabilizados separadamente; não são removidos por substituição de bytes em executáveis. Se a imagem foi compilada em outro diretório, informe o caminho exato com `--build-root /caminho/original/do/codigo`. Essa exceção não permite caminhos antigos de configuração ou comandos de execução.

## Licença e atribuições

O projeto é distribuído sob as licenças presentes no diretório `licenses`. Componentes de terceiros mantêm suas licenças e atribuições originais nos respectivos arquivos-fonte e repositórios derivados.

## Atenção

Imagens devem ser testadas no modelo exato do equipamento antes de instalação em eMMC. Uma configuração DTB incorreta pode impedir a inicialização.

Esta versão altera caminhos, chaves de configuração e rótulos de partição. Use uma instalação nova para validação; a migração de instalações anteriores ainda não foi homologada. O catálogo de atualização só deve anunciar versões depois da publicação dos respectivos arquivos e checksums.
