# Odonto — app Flutter (web + Android + iOS)

Front-end da clínica odontológica. Um único código Flutter para **web**, **Android** e **iOS**,
com layouts diferentes para desktop e mobile. O backend é o Supabase do repositório
[`supabase`](https://github.com/zeoliveirajunior/supabase): o app **nunca** lê tabelas, só chama
functions (`rpc`) que validam a sessão no banco. Leia o [CLAUDE.md](CLAUDE.md) para as regras.

## Rodar

```bash
flutter pub get
flutter run -d chrome          # homologação por default
flutter test
```

## Telas

| Tela | Estado |
|---|---|
| Login (3 layouts: desktop, tablet, mobile) | pronta |
| Seleção de empresa/filial (pop-up com pesquisa, só quando há mais de uma) | pronta |
| Dashboard | em branco, aguardando dados |
| Cadastro de usuários, perfis, logs | próximas |

## Publicação

PR → `staging` (homologação) → PR → `main` (produção). Deploys são manuais, um workflow por
plataforma (`Deploy Web`, `Deploy Android`, `Deploy iOS`), e a branch escolhida ao disparar define o
ambiente. Detalhes e secrets necessários no [CLAUDE.md](CLAUDE.md).
