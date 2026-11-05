# Clima Agora

Aplicativo Flutter em português que consulta o clima atual de uma cidade usando a API REST Open-Meteo.

## Como executar

Com o Flutter instalado, na raiz do projeto:

```sh
flutter pub get
flutter run -d chrome
```

Também é possível gerar os arquivos estáticos para hospedagem com `flutter build web`.

## API e fluxo de dados

1. O app envia uma requisição HTTP GET para a API de geocodificação da Open-Meteo e converte a resposta JSON para localizar a cidade.
2. Com latitude e longitude, envia outro GET para a API de previsão.
3. `async`/`await` aguarda as respostas sem bloquear a interface. Os dados exibidos incluem temperatura, sensação térmica, umidade, vento e descrição do tempo.
4. A tela mostra carregamento, erros de rede/cidade inválida e permite tentar novamente.

As requisições usam `package:http`, compatível com navegador e dispositivos móveis. Não é necessária uma chave de API. Consulte os serviços em [Geocoding API](https://open-meteo.com/en/docs/geocoding-api) e [Weather Forecast API](https://open-meteo.com/en/docs).
