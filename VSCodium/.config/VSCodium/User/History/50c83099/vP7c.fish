if status is-interactive
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
end
