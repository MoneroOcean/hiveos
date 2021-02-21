mo_gminer is HiveOS custom GPU miner package based on https://github.com/MoneroOcean/meta-miner
miner wrapper over gminer (https://github.com/develsoftware/GMinerRelease)
that allows auto switching to the most profitable GPU algo
if used to mine to MoneroOcean (moneroocean.stream) pool.

List of supported algos:

    ethash
    kawpow
    c29s
    c29b

Miner wrapper adds algo benchmark for each suported algo
during its first run and reporting that algo_perf data to the pool that in case of
moneroocean.stream pool allows it to offer the most profitable algo jobs for your miner
based on current coin prices and difficulties.