# Turborama

Turborama é um sistema operacional de jogos retro para dispositivos Amlogic, com interface EmulationStation, RetroArch, emuladores standalone e suporte a instalação em cartão SD, USB e eMMC compatível.

## Versão

- Produto: Turborama
- Versão: 1.0
- Codinome: Genesis
- Arquitetura: aarch64
- Projeto: Amlogic-ce
- Dispositivo: Amlogic-ng

## Compilação

```bash
git clone https://github.com/luziellacerda/TURBOBOX-SET2026.git
cd TURBOBOX-SET2026
git checkout turborama-1.0
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64 DISTRO=Turborama make image
```

## Identidade do sistema

A distribuição, partição de boot, diretórios de configuração, comandos, serviços, logs, telas, hostname e arquivos gerados usam a identidade Turborama.

A partição de boot usa o rótulo `TURBORAMA`, os dados do sistema usam `STORAGE` e a partição de jogos usa `TURBOROMS`. As configurações ficam em `/storage/.config/turborama`, acessíveis pelo link `/turborama`. A inicialização usa `turborama.target`, com o frontend em `emustation.service`.

## Verificação local

```bash
python3 -m unittest discover -s tests -p 'test_turborama_*.py' -v
```

Os testes verificam configurações, versões, identidade de dispositivo, checksum de atualização, tratamento de teclas, contratos de inicialização e referências de identidade nos arquivos rastreados. A inspeção de texto preserva os créditos originais e não substitui a revisão de imagens e binários nem o teste de boot no hardware.

## Licença e atribuições

O projeto é distribuído sob as licenças presentes no diretório `licenses`. Componentes de terceiros mantêm suas licenças e atribuições originais nos respectivos arquivos-fonte e repositórios derivados.

## Atenção

Imagens devem ser testadas no modelo exato do equipamento antes de instalação em eMMC. Uma configuração DTB incorreta pode impedir a inicialização.

Esta versão altera caminhos, chaves de configuração e rótulos de partição. Use uma instalação nova para validação; a migração de instalações anteriores ainda não foi homologada. O catálogo de atualização só deve anunciar versões depois da publicação dos respectivos arquivos e checksums.
