if status is-interactive
    set -g fish_greeting ""
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



end
