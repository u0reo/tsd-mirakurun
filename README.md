# tsd: mirakurun

mirakurun以外にもb25対応のrecpt1やカードリーダーのpcsc-toolsを含むコンテナ。alpineベースのNode.jsのイメージを採用することで、本家と比べ軽量化を実現。

ホストマシンでは、チューナーに対応したドライバのインストールが必要。カードリーダーのドライバは不要。

## コンテナ内にある主なソフトウェア

[![Chinachu/Mirakurun - GitHub](https://gh-card.dev/repos/Chinachu/Mirakurun.svg)](https://github.com/Chinachu/Mirakurun)

[![stz2012/libarib25 - GitHub](https://gh-card.dev/repos/stz2012/libarib25.svg)](https://github.com/stz2012/libarib25)

[![stz2012/recpt1 - GitHub](https://gh-card.dev/repos/stz2012/recpt1.svg)](https://github.com/stz2012/recpt1)

[![LudovicRousseau/pcsc-tools - GitHub](https://gh-card.dev/repos/LudovicRousseau/pcsc-tools.svg)](https://github.com/LudovicRousseau/pcsc-tools)

## 初期化

対応チューナーならば、チューナーの設定をこのコマンド1つで可能。

リストにない場合は手動で`config/tuners.yml`の設定が必要。

また、チャンネル設定は東京のもの。

```sh
./init.sh tuner_model
```

## 追加済みチューナーリスト(tuner_model)

- dtv02_1t1s
- dtv02_4ts
- px_mlt5
- px_mlt8
- px_q3
- px_w3

## テスト

事前にmirakurunコンテナを停止

```sh
docker stop tsd-mirakurun
```

### B-CASカード

```sh
docker exec -it mirakurun pcsc_scan -t 5
```

### 録画テスト

5秒間録画し、保存。

```sh
docker exec -it mirakurun recpt1 --b25 --device /dev/px4video2 --strip 22 5 - > test.ts
```

## 参考

[recpt1 で Cannot start b25 decoder - Qiita](https://qiita.com/nanbuwks/items/4b26ce36d07824411633)
