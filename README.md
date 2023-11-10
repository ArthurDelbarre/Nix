# How to lauch

After booting on a nix iso, run the following command :

```sh
nix run --extra-experimental-features nix-command --extra-experimental-features flakes "github:ArthurDelbarre/Nix#partitioning" --no-write-lock-file
```