(function()
    -- --- 1. Dependencies and Initialization (Must run first) ---
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    -- Exit if player object is not available
    if not LocalPlayer then return end 
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- State Variables for Memory Alchemy
    local ScannedReferences = {}
    local CurrentScanType = 0 -- 0: Initial Scan, 1: Filter Scan
    local TargetInstances = {game} -- Scan from the root of the DataModel
    local YIELD_INTERVAL = 1000 -- Increased yield check for stability
    local yieldCounter = 0
    
    -- State Variables for Physical Transcendence
    local isNoclipActive = false
    local isFlyActive = false
    local FLY_SPEED = 50 
    local FLY_VECTOR = Vector3.new(0, 0, 0)
    local FLY_CONNECTION = nil
    
    -- Setup character access function
    local function getCharacterAndHRP()
        local character = LocalPlayer.Character
        if not character then return nil, nil end
        local HRP = character:FindFirstChild("HumanoidRootPart")
        return character, HRP
    end
    
    -- --- 2. UI Construction ---
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AetherWeaverGUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25) 
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true -- Crucial for usability
    mainFrame.Parent = screenGui
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    
    -- Title Bar
    local title = Instance.new("TextLabel")
    title.Text = "THE AETHER WEAVER (V4.1)"
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    title.Parent = mainFrame
    
    -- Tab Bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 35)
    tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    tabBar.Parent = mainFrame
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 1, -75)
    tabContainer.Position = UDim2.new(0, 0, 0, 75)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    -- --- 2.1 Tab Buttons ---
    local memoryTabButton = Instance.new("TextButton")
    memoryTabButton.Name = "MemoryTab"
    memoryTabButton.Text = "MEMORY ALCHEMY"
    memoryTabButton.Size = UDim2.new(0.5, 0, 1, 0)
    memoryTabButton.Position = UDim2.new(0, 0, 0, 0)
    memoryTabButton.Font = Enum.Font.SourceSansBold
    memoryTabButton.TextSize = 14
    memoryTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    memoryTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    memoryTabButton.Parent = tabBar
    
    local physicalTabButton = Instance.new("TextButton")
    physicalTabButton.Name = "PhysicalTab"
    physicalTabButton.Text = "PHYSICAL TRANSCENDENCE"
    physicalTabButton.Size = UDim2.new(0.5, 0, 1, 0)
    physicalTabButton.Position = UDim2.new(0.5, 0, 0, 0)
    physicalTabButton.Font = Enum.Font.SourceSansBold
    physicalTabButton.TextSize = 14
    physicalTabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    physicalTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    physicalTabButton.Parent = tabBar

    -- --- 2.2 Memory Alchemy Tab (Scan/Filter/Rewrite) ---
    local memoryFrame = Instance.new("Frame")
    memoryFrame.Name = "MemoryAlchemy"
    memoryFrame.Size = UDim2.new(1, 0, 1, 0)
    memoryFrame.BackgroundTransparency = 1
    memoryFrame.Parent = tabContainer

    -- Reference Count Display
    local countLabel = Instance.new("TextLabel")
    countLabel.Text = "REFERENCES FOUND: 0"
    countLabel.Size = UDim2.new(1, -20, 0, 30)
    countLabel.Position = UDim2.new(0, 10, 0, 10)
    countLabel.Font = Enum.Font.Code
    countLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    countLabel.TextSize = 16
    countLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    countLabel.Parent = memoryFrame
    
    -- Status and Tips Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = "Status: Initializing Aether Cores..."
    statusLabel.Size = UDim2.new(1, -20, 0, 40)
    statusLabel.Position = UDim2.new(0, 10, 0, 50)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextColor3 = Color3.fromRGB(150, 255, 255)
    statusLabel.TextSize = 13
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = memoryFrame
    
    -- Input Fields
    local yOffset = 100
    
    local searchBox = Instance.new("TextBox")
    searchBox.PlaceholderText = "CURRENT Value to Match (e.g., 500)"
    searchBox.Size = UDim2.new(1, -20, 0, 35)
    searchBox.Position = UDim2.new(0, 10, 0, yOffset)
    searchBox.Font = Enum.Font.SourceSans
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 16
    searchBox.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    searchBox.Parent = memoryFrame
    yOffset = yOffset + 45
    
    local changeBox = Instance.new("TextBox")
    changeBox.PlaceholderText = "NEW Value to Rewrite (e.g., 999999)"
    changeBox.Size = UDim2.new(1, -20, 0, 35)
    changeBox.Position = UDim2.new(0, 10, 0, yOffset)
    changeBox.Font = Enum.Font.SourceSans
    changeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeBox.TextSize = 16
    changeBox.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    changeBox.Parent = memoryFrame
    yOffset = yOffset + 55
    
    -- Buttons
    local buttonHeight = 40
    local buttonWidth = (350 - 40) / 3
    local buttonY = yOffset

    local scanButton = Instance.new("TextButton")
    scanButton.Text = "START NEW SCAN"
    scanButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    scanButton.Position = UDim2.new(0, 10, 0, buttonY)
    scanButton.Font = Enum.Font.SourceSansBold
    scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanButton.TextSize = 14
    scanButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    scanButton.Parent = memoryFrame
    Instance.new("UICorner", scanButton).CornerRadius = UDim.new(0, 6)
    
    local filterButton = Instance.new("TextButton")
    filterButton.Text = "FILTER"
    filterButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    filterButton.Position = UDim2.new(0, 20 + buttonWidth, 0, buttonY)
    filterButton.Font = Enum.Font.SourceSansBold
    filterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    filterButton.TextSize = 14
    filterButton.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    filterButton.Parent = memoryFrame
    Instance.new("UICorner", filterButton).CornerRadius = UDim.new(0, 6)

    local changeButton = Instance.new("TextButton")
    changeButton.Text = "REWRITE ALL"
    changeButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    changeButton.Position = UDim2.new(0, 30 + (buttonWidth * 2), 0, buttonY)
    changeButton.Font = Enum.Font.SourceSansBold
    changeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeButton.TextSize = 14
    changeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    changeButton.Parent = memoryFrame
    Instance.new("UICorner", changeButton).CornerRadius = UDim.new(0, 6)

    local resetButton = Instance.new("TextButton")
    resetButton.Text = "RESET (Clear References)"
    resetButton.Size = UDim2.new(1, -20, 0, 30)
    resetButton.Position = UDim2.new(0, 10, 0, buttonY + buttonHeight + 10)
    resetButton.Font = Enum.Font.SourceSans
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.TextSize = 14
    resetButton.BackgroundColor3 = Color3.fromRGB(90, 90, 120) 
    resetButton.Parent = memoryFrame
    Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 6)

    -- --- 2.3 Physical Transcendence Tab (Noclip/Fly) ---
    local physicalFrame = Instance.new("Frame")
    physicalFrame.Name = "PhysicalTranscendence"
    physicalFrame.Size = UDim2.new(1, 0, 1, 0)
    physicalFrame.BackgroundTransparency = 1
    physicalFrame.Visible = false
    physicalFrame.Parent = tabContainer

    local physY = 10

    -- Noclip Toggle
    local noclipLabel = Instance.new("TextLabel")
    noclipLabel.Text = "NOCLIP (Collision Bypass)"
    noclipLabel.Size = UDim2.new(0.7, 0, 0, 40)
    noclipLabel.Position = UDim2.new(0, 10, 0, physY)
    noclipLabel.Font = Enum.Font.SourceSansBold
    noclipLabel.TextXAlignment = Enum.TextXAlignment.Left
    noclipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    noclipLabel.TextSize = 16
    noclipLabel.BackgroundTransparency = 1
    noclipLabel.Parent = physicalFrame

    local noclipToggle = Instance.new("TextButton")
    noclipToggle.Name = "NoclipToggle"
    noclipToggle.Text = "OFF"
    noclipToggle.Size = UDim2.new(0.2, 0, 0, 40)
    noclipToggle.Position = UDim2.new(0.75, 0, 0, physY)
    noclipToggle.Font = Enum.Font.SourceSansBold
    noclipToggle.TextSize = 16
    noclipToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50) 
    noclipToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", noclipToggle).CornerRadius = UDim.new(0, 6)
    noclipToggle.Parent = physicalFrame
    physY = physY + 50

    -- Fly Toggle
    local flyLabel = Instance.new("TextLabel")
    flyLabel.Text = "FLY MODE (Q=Up, E=Down)"
    flyLabel.Size = UDim2.new(0.7, 0, 0, 40)
    flyLabel.Position = UDim2.new(0, 10, 0, physY)
    flyLabel.Font = Enum.Font.SourceSansBold
    flyLabel.TextXAlignment = Enum.TextXAlignment.Left
    flyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyLabel.TextSize = 16
    flyLabel.BackgroundTransparency = 1
    flyLabel.Parent = physicalFrame

    local flyToggle = Instance.new("TextButton")
    flyToggle.Name = "FlyToggle"
    flyToggle.Text = "OFF"
    flyToggle.Size = UDim2.new(0.2, 0, 0, 40)
    flyToggle.Position = UDim2.new(0.75, 0, 0, physY)
    flyToggle.Font = Enum.Font.SourceSansBold
    flyToggle.TextSize = 16
    flyToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50) 
    flyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", flyToggle).CornerRadius = UDim.new(0, 6)
    flyToggle.Parent = physicalFrame
    physY = physY + 50
    
    -- Fly Speed Slider
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Text = "Fly Speed: 50"
    speedLabel.Size = UDim2.new(1, -20, 0, 20)
    speedLabel.Position = UDim2.new(0, 10, 0, physY)
    speedLabel.Font = Enum.Font.SourceSans
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.TextColor3 = Color3.fromRGB(150, 255, 255)
    speedLabel.TextSize = 14
    speedLabel.BackgroundTransparency = 1
    speedLabel.Parent = physicalFrame
    physY = physY + 25

    local speedSlider = Instance.new("Slider")
    speedSlider.Size = UDim2.new(1, -20, 0, 20)
    speedSlider.Position = UDim2.new(0, 10, 0, physY)
    speedSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    speedSlider.Parent = physicalFrame
    speedSlider.Value = 0.5 -- Normalized value (0.5 means 50 speed)
    speedSlider.Min = 0.1
    speedSlider.Max = 1.0
    physY = physY + 30
    
    -- --- 3. Core Logic Functions ---

    local function updateStatus(text, color)
        statusLabel.Text = text
        statusLabel.TextColor3 = color or Color3.fromRGB(150, 255, 255)
        countLabel.Text = "REFERENCES FOUND: " .. #ScannedReferences
    end

    -- Recursive Scan Function
    local function recursiveScan(instance, valueToMatch)
        local results = {}
        
        -- Simple check to skip huge, irrelevant areas
        if not instance or instance:IsA("Texture") or instance:IsA("Decal") or instance:IsA("Light") then
            return results
        end
        
        -- Performance Fix: Yield the thread to prevent crashing
        yieldCounter = yieldCounter + 1
        if yieldCounter >= YIELD_INTERVAL then
            task.wait() 
            yieldCounter = 0
        end

        local success, children = pcall(instance.GetChildren, instance)
        if not success or not children then return results end

        for _, child in ipairs(children) do
            -- Optimization: Skip parts likely not to hold values
            local isIgnored = child:IsA("BasePart") or child:IsA("MeshPart")
            if isIgnored and not child:FindFirstChildOfClass("Humanoid") then
                -- Still recurse into models/assemblies containing parts
                local childResults = recursiveScan(child, valueToMatch)
                for _, ref in ipairs(childResults) do
                    table.insert(results, ref)
                end
                goto continue
            end
            
            local propSuccess, props = pcall(child.GetProperties, child)
            if propSuccess and props then
                for propName, propInfo in pairs(props) do
                    -- Target numerical types (number, int, float)
                    if propInfo.Type.Name == 'number' or propInfo.Type.Name == 'int' or propInfo.Type.Name == 'float' then
                        local valSuccess, value = pcall(function() return child[propName] end)
                        
                        if valSuccess and value == valueToMatch then
                            local reference = {
                                Instance = child,
                                PropertyName = propName,
                            }
                            table.insert(results, reference)
                        end
                    end
                end
            end
            
            -- Recurse into children
            local childResults = recursiveScan(child, valueToMatch)
            for _, ref in ipairs(childResults) do
                table.insert(results, ref)
            end
            ::continue::
        end
        return results
    end
    
    -- --- 4. Physical Transcendence Functions ---
    
    -- 4.1 Noclip Implementation
    local function setNoclip(enabled)
        isNoclipActive = enabled
        local character, hrp = getCharacterAndHRP()
        
        if not character then 
            updateStatus("Noclip: Character not found!", Color3.fromRGB(255, 100, 100))
            isNoclipActive = false -- Reset state if character is gone
            return 
        end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = not enabled
            end
        end
        
        noclipToggle.Text = enabled and "ON" or "OFF"
        noclipToggle.BackgroundColor3 = enabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(150, 50, 50)
    end

    -- 4.2 Fly Implementation
    local function setFly(enabled)
        isFlyActive = enabled
        local character, HRP = getCharacterAndHRP()

        if not character or not HRP then
            updateStatus("Fly: Character/HRP not found!", Color3.fromRGB(255, 100, 100))
            isFlyActive = false
            return 
        end

        local Humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if enabled then
            Humanoid.PlatformStand = true
            
            -- Ensure existing connection is disconnected if somehow re-enabled
            if FLY_CONNECTION then FLY_CONNECTION:Disconnect() end

            FLY_CONNECTION = RunService.Heartbeat:Connect(function()
                if not HRP or not isFlyActive then return end

                local camera = workspace.CurrentCamera
                
                -- Calculate movement direction relative to camera
                local moveVector = Vector3.new(0, 0, 0)
                if FLY_VECTOR.Z ~= 0 then -- Forward/Backward
                    moveVector = moveVector + camera.CFrame.LookVector * FLY_VECTOR.Z
                end
                if FLY_VECTOR.X ~= 0 then -- Left/Right
                    moveVector = moveVector + camera.CFrame.RightVector * FLY_VECTOR.X
                end
                
                -- Up/Down (Absolute Y)
                moveVector = moveVector + Vector3.new(0, FLY_VECTOR.Y, 0)
                
                -- Apply movement to HRP
                if moveVector.Magnitude > 0 then
                    local speed = FLY_SPEED / 60 -- Compensate for frame rate
                    HRP.CFrame = HRP.CFrame + moveVector.Unit * speed
                    HRP.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Stop physics interference
                end
            end)
        else
            if FLY_CONNECTION then FLY_CONNECTION:Disconnect() end
            Humanoid.PlatformStand = false
            -- Note: We don't need to reset CustomPhysicalProperties if we stop movement by setting velocity to zero/using CFrame.
            HRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
        
        flyToggle.Text = enabled and "ON" or "OFF"
        flyToggle.BackgroundColor3 = enabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(150, 50, 50)
    end
    
    -- --- 5. Event Handlers ---
    
    -- 5.1 Tab Switching
    local function switchTab(frameName)
        memoryFrame.Visible = (frameName == memoryFrame.Name)
        physicalFrame.Visible = (frameName == physicalFrame.Name)
        
        memoryTabButton.BackgroundColor3 = memoryFrame.Visible and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(30, 30, 45)
        memoryTabButton.TextColor3 = memoryFrame.Visible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        
        physicalTabButton.BackgroundColor3 = physicalFrame.Visible and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(30, 30, 45)
        physicalTabButton.TextColor3 = physicalFrame.Visible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    end
    
    -- 5.2 Noclip/Fly Toggles
    noclipToggle.MouseButton1Click:Connect(function()
        setNoclip(not isNoclipActive)
    end)

    flyToggle.MouseButton1Click:Connect(function()
        setFly(not isFlyActive)
    end)
    
    speedSlider.Changed:Connect(function(value)
        FLY_SPEED = math.round(value * 100) -- Map 0.1-1.0 to 10-100 speed
        speedLabel.Text = "Fly Speed: " .. FLY_SPEED
    end)
    
    -- 5.3 Fly Movement Keybinds
    local function handleMovementInput(input, gameProcessed, isBegan)
        if gameProcessed or not isFlyActive then return end
        
        local factor = isBegan and 1 or -1
        
        if input.KeyCode == Enum.KeyCode.W then
            FLY_VECTOR = FLY_VECTOR + Vector3.new(0, 0, -1) * factor
        elseif input.KeyCode == Enum.KeyCode.S then
            FLY_VECTOR = FLY_VECTOR + Vector3.new(0, 0, 1) * factor
        elseif input.KeyCode == Enum.KeyCode.A then
            FLY_VECTOR = FLY_VECTOR + Vector3.new(-1, 0, 0) * factor
        elseif input.KeyCode == Enum.KeyCode.D then
            FLY_VECTOR = FLY_VECTOR + Vector3.new(1, 0, 0) * factor
        elseif input.KeyCode == Enum.KeyCode.E then
            FLY_VECTOR = FLY_VECTOR + Vector3.new(0, 1, 0) * factor -- Up
        elseif input.KeyCode == Enum.KeyCode.Q then
            FLY_VECTOR = FLY_VECTOR + Vector3.new(0, -1, 0) * factor -- Down
        end
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        handleMovementInput(input, gameProcessed, true)
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        handleMovementInput(input, gameProcessed, false)
    end)

    -- 5.4 Memory Alchemy Buttons
    scanButton.MouseButton1Click:Connect(function()
        local targetValue = tonumber(searchBox.Text)
        if not targetValue then
            updateStatus("Status: ERROR - Invalid number. Must be a whole or decimal number.", Color3.fromRGB(255, 100, 100))
            return
        end
        
        updateStatus("Status: Initializing FULL Recursive Scan (Game Root)... Please wait.", Color3.fromRGB(255, 200, 0))
        
        local newScanSet = {}
        ScannedReferences = {}
        CurrentScanType = 0
        
        local start = tick()
        for _, root in ipairs(TargetInstances) do
            if root then
                local scanPart = recursiveScan(root, targetValue)
                for _, ref in ipairs(scanPart) do
                    table.insert(newScanSet, ref)
                end
            end
        end
        
        ScannedReferences = newScanSet
        CurrentScanType = 1
        local duration = string.format("%.2f", tick() - start)
        
        updateStatus(string.format("Status: Initial Scan Complete! Found %d references in %s seconds. Now, change value in-game and press FILTER.", #ScannedReferences, duration), Color3.fromRGB(150, 255, 150))
        filterButton.Text = "FILTER (" .. #ScannedReferences .. ")"
        scanButton.Text = "RESTART SCAN"
    end)
    
    filterButton.MouseButton1Click:Connect(function()
        if CurrentScanType == 0 then
            updateStatus("Status: Please press 'START NEW SCAN' first.", Color3.fromRGB(255, 150, 0))
            return
        end
        
        local targetValue = tonumber(searchBox.Text)
        if not targetValue then
            updateStatus("Status: ERROR - Invalid number in search box. Must be a number.", Color3.fromRGB(255, 100, 100))
            return
        end
        
        updateStatus(string.format("Status: Filtering %d references by new value %d...", #ScannedReferences, targetValue), Color3.fromRGB(255, 180, 50))
        
        local newFilteredSet = {}
        local start = tick()
        
        for _, ref in ipairs(ScannedReferences) do
            local success, currentValue = pcall(function() return ref.Instance[ref.PropertyName] end)
            
            if success and currentValue == targetValue then
                table.insert(newFilteredSet, ref)
            end
            
            yieldCounter = yieldCounter + 1
            if yieldCounter >= YIELD_INTERVAL * 2 then 
                task.wait() 
                yieldCounter = 0
            end
        end
        
        ScannedReferences = newFilteredSet
        local duration = string.format("%.2f", tick() - start)
        
        if #ScannedReferences <= 5 and #ScannedReferences > 0 then
            updateStatus(string.format("Status: FILTER COMPLETE! Found %d unique target(s) in %s seconds. Proceed to REWRITE ALL.", #ScannedReferences, duration), Color3.fromRGB(0, 255, 100))
        elseif #ScannedReferences == 0 then
            updateStatus("Status: FILTER FAILED! Found 0 references. The value might be protected or not client-side. Press RESET.", Color3.fromRGB(255, 50, 50))
        else
            updateStatus(string.format("Status: Filtered to %d references in %s seconds. Change the value again and press FILTER!", #ScannedReferences, duration), Color3.fromRGB(150, 255, 255))
        end
        filterButton.Text = "FILTER (" .. #ScannedReferences .. ")"
    end)
    
    changeButton.MouseButton1Click:Connect(function()
        local newValue = tonumber(changeBox.Text)
        if not newValue then
            updateStatus("Status: ERROR - Invalid number in NEW Value box.", Color3.fromRGB(255, 100, 100))
            return
        end
        
        if #ScannedReferences == 0 then
            updateStatus("Status: ERROR - Perform a successful scan first.", Color3.fromRGB(255, 150, 0))
            return
        end
        
        local successCount = 0
        local totalCount = #ScannedReferences
        
        updateStatus(string.format("Status: Initiating REWRITE! Total targets: %d...", totalCount), Color3.fromRGB(255, 50, 50))
        
        for _, ref in ipairs(ScannedReferences) do
            local success, err = pcall(function()
                ref.Instance[ref.PropertyName] = newValue
            end)
            
            if success then
                successCount = successCount + 1
            end
        end
        
        ScannedReferences = {}
        CurrentScanType = 0
        
        updateStatus(string.format("Status: REWRITE COMPLETE! %d/%d values liberated to %d. Press RESET and START NEW SCAN.", successCount, totalCount, newValue), Color3.fromRGB(0, 255, 100))
        filterButton.Text = "FILTER (0)"
        scanButton.Text = "START NEW SCAN"
        countLabel.Text = "REFERENCES FOUND: 0"
    end)
    
    resetButton.MouseButton1Click:Connect(function()
        ScannedReferences = {}
        CurrentScanType = 0
        updateStatus("Status: State fully RESET. Ready for new Initial Scan.", Color3.fromRGB(150, 255, 255))
        countLabel.Text = "REFERENCES FOUND: 0"
        filterButton.Text = "FILTER (0)"
        scanButton.Text = "START NEW SCAN"
    end)
    
    -- Final Initialization
    switchTab(memoryFrame.Name)
    updateStatus("Status: Ready. Enter CURRENT value and START NEW SCAN.", Color3.fromRGB(150, 255, 255))
    
    -- Ensure Noclip/Fly reset if the character dies
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        setNoclip(false)
        setFly(false)
    end)
    
end)()
