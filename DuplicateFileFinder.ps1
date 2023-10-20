Clear-Host

# Define the target folder
$folderPath = 'C:\Obsidian-LocalOnly'

# Define the mode: 'name' or 'content'
$mode = 'name'

# Get all file info objects from the directory excluding hidden folders
$files = Get-ChildItem -Path $folderPath -File -Recurse | Where-Object { $_.FullName -notmatch '\\\.' }

# Create an empty hashtable to store file info
$hashTable = @{}

# Create an empty array to store delete commands
$deleteCommands = @()

# Loop through the files
foreach ($file in $files)
{
    if ($mode -eq 'name') {
        # Use file name for comparison
        $key = $file.Name
    }
    else {
        # Use file content for comparison (calculate the hash for each file)
        $hash = Get-FileHash -Path $file.FullName -Algorithm MD5
        $key = $hash.Hash
    }

    # If the key is already in the hashtable, append the file to the array
    if ($hashTable.ContainsKey($key))
    {
        $hashTable[$key] += ,$file
    }
    else
    {
        # If the key is not in the hashtable, add it with an array containing the file
        $hashTable[$key] = @($file)
    }
}

# Display groups of duplicates and generate delete commands
foreach ($key in $hashTable.Keys)
{
    if ($hashTable[$key].Count -gt 1)
    {
        Write-Output ("Duplicates detected for `{0}`:" -f $key)
        foreach ($file in $hashTable[$key])
        {
            Write-Output $file.FullName
            
            # Check if file contents are identical
            $hash = Get-FileHash -Path $file.FullName -Algorithm MD5
            if ($hash.Hash -eq $key) {
                Write-Output "File contents are identical."
            } else {
                Write-Output "File contents differ."
            }
        }

        # Sort files by nesting level (count of backslashes in path), and select the one with least nesting
        $leastNestedFile = $hashTable[$key] | Sort-Object { ($_ -split '\\').Count } | Select-Object -First 1

        # Generate delete command for least nested duplicate and add to list
        $deleteCommands += ("Remove-Item -Path `"{0}`"" -f $leastNestedFile.FullName)
    }
}

# Display all delete commands
Write-Output "To delete the least nested duplicates, you can run the following commands:"
$deleteCommands | ForEach-Object {
    Write-Output $_
}