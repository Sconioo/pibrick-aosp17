#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-apply}"

die() {
    printf 'ERREUR : %s\n' "$*" >&2
    exit 1
}

verify_package() {
    (
        cd "$ROOT"
        sha256sum -c SHA256SUMS
    )
}

detect_state() {
    chmod +x "$ROOT/tools/detect-services-state-rpiboot.sh"
    "$ROOT/tools/detect-services-state-rpiboot.sh"
}

run_v6() {
    (
        cd "$ROOT/components/v6"
        chmod +x install.sh
        ./install.sh
    )
}

run_v7_framework() {
    (
        cd "$ROOT/components/audio"
        chmod +x install.sh
        ./install.sh apply
    )
}

run_v7_route() {
    chmod +x "$ROOT/tools/audio-route-rpiboot.sh"
    "$ROOT/tools/audio-route-rpiboot.sh" apply
}

run_v8() {
    (
        cd "$ROOT/components/v8"
        chmod +x install.sh
        ./install.sh apply
    )
}

finish_message() {
    printf '\n============================================================\n'
    printf 'INSTALLATION V8 TERMINÉE\n'
    printf '============================================================\n'
    printf 'Quitte le mode rpiboot et démarre Android normalement.\n'
    printf 'Puis lance :\n'
    printf '  ADB_TARGET=192.168.1.168:5555 ./tools/verify-after-boot.sh\n'
}

apply_automatic() {
    local state

    printf '%s\n' '===== V8 — CONTRÔLE DU PAQUET ====='
    verify_package

    state="$(detect_state)"
    printf '\nÉtat services détecté : %s\n' "$state"

    case "$state" in
        v8)
            printf '\n%s\n' \
                '===== PHASE 1/4 — BASE V6 CONSERVÉE ====='
            printf '%s\n' \
                '===== PHASE 2/4 — FRAMEWORK V7 CONSERVÉ ====='
            printf '%s\n' \
                '===== PHASE 3/4 — FRAMEWORK V8 DÉJÀ ACQUIS ====='
            ;;

        v7)
            printf '\n%s\n' \
                '===== PHASE 1/4 — BASE V6 CONSERVÉE ====='
            printf '%s\n' \
                '===== PHASE 2/4 — FRAMEWORK V7 CONSERVÉ ====='
            printf '\n%s\n' \
                '===== PHASE 3/4 — PASSAGE AU FRAMEWORK V8 ====='
            ;;

        v6)
            printf '\n%s\n' \
                '===== PHASE 1/4 — BASE V6 CONSERVÉE ====='
            printf '\n%s\n' \
                '===== PHASE 2/4 — INSTALLATION DU FRAMEWORK V7 ====='
            run_v7_framework
            printf '\n%s\n' \
                '===== PHASE 3/4 — PASSAGE AU FRAMEWORK V8 ====='
            ;;

        other)
            printf '\n%s\n' \
                '===== PHASE 1/4 — INSTALLATION DE LA BASE V6 ====='
            run_v6
            printf '\n%s\n' \
                '===== PHASE 2/4 — INSTALLATION DU FRAMEWORK V7 ====='
            run_v7_framework
            printf '\n%s\n' \
                '===== PHASE 3/4 — PASSAGE AU FRAMEWORK V8 ====='
            ;;

        *)
            die "état services inconnu : $state"
            ;;
    esac

    printf '\n%s\n' \
        '===== ROUTE AUDIO V7 — DAC ====='
    run_v7_route

    printf '\n%s\n' \
        '===== PHASE 4/4 — ÉTAT FINAL V8 ====='
    run_v8

    finish_message
}

case "$ACTION" in
    verify)
        verify_package
        ;;

    status)
        verify_package
        printf 'État services : %s\n' "$(detect_state)"
        "$ROOT/tools/audio-route-rpiboot.sh" status
        "$ROOT/components/v8/install.sh" status
        ;;

    apply)
        apply_automatic
        ;;

    apply-stock)
        verify_package
        run_v6
        run_v7_framework
        run_v7_route
        run_v8
        finish_message
        ;;

    upgrade-from-v7)
        verify_package
        state="$(detect_state)"
        [[ "$state" == v7 ]] ||
            die "état attendu v7, état trouvé : $state"
        run_v7_route
        run_v8
        finish_message
        ;;

    rollback-v8)
        (
            cd "$ROOT/components/v8"
            ./install.sh rollback
        )
        ;;

    rollback-route)
        "$ROOT/tools/audio-route-rpiboot.sh" rollback
        ;;

    *)
        die "action inconnue : $ACTION
Actions :
  ./install.sh
  ./install.sh verify
  ./install.sh status
  ./install.sh apply-stock
  ./install.sh upgrade-from-v7
  ./install.sh rollback-v8
  ./install.sh rollback-route"
        ;;
esac
