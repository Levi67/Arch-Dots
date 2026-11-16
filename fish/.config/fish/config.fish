if status is-interactive
    # Prompt + fastfetch colors follow the desktop theme (wallust / winter mode).
    # ~/.config/scripts/term-theme writes ~/.cache/term-theme and sends SIGUSR2
    # to every shell registered below, which repaints the prompt live.
    set -l term_theme ~/.cache/term-theme
    test -s $term_theme/starship.toml; or ~/.config/scripts/term-theme
    test -s $term_theme/starship.toml; and set -gx STARSHIP_CONFIG $term_theme/starship.toml

    set -g __term_theme_pid $XDG_RUNTIME_DIR/term-theme/fish/$fish_pid
    mkdir -p (path dirname $__term_theme_pid); and touch $__term_theme_pid
    function __term_theme_repaint --on-signal SIGUSR2
        commandline -f repaint
    end
    function __term_theme_unregister --on-event fish_exit
        rm -f $__term_theme_pid
    end

    # Show fastfetch as the greeting for every new interactive shell
    function fish_greeting
        fastfetch (cat ~/.cache/term-theme/fastfetch.args 2>/dev/null)
    end
    # Commands to run in interactive sessions can go here


    # Initialize zoxide normally
    zoxide init fish | source

    # Rebind z to act as your primary directory switcher (smart cd)
    # (Zoxide's 'z' command already handles paths and directories like cd, 
    #   but if you want 'z' to invoke zoxide and 'ci' to do the interactive search:)

    function cd
        __zoxide_z $argv
    end

    function ci
        __zoxide_zi $argv
    end

    function start-black-camera
        echo "Starting black virtual camera on /dev/video9..."
        ffmpeg -f lavfi -i color=c=black:s=1920x1080:r=30 -pix_fmt yuv420p -f v4l2 /dev/video9
    end


    starship init fish | source

end
