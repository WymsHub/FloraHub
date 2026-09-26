task.spawn(function()
    while true do
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local remote = rs:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("SetControls")
            remote:FireServer("VR") -- Modes: "VR" (VR Display) "Gamepad" (Controler Display), "MouseKeyboard" (PC)
        end)
        task.wait(0)
    end
end)
