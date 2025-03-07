# Define input and output file names

# raw data comes from https://www.inegi.org.mx/app/api/indicadores/interna_v1_3//CalculadoraINPInformacion/865541/null/json/96fbd1bf-21e6-28e3-6e64-2b15999d2c89?callback=jQuery1112015306454891067345_1741383579635&_=1741383579636
$inputFile = "rawdata.txt"
$outputFile = "output.json"

# Define a mapping of Spanish month names to numbers
$monthMap = @{
    "Ene" = 1; "Feb" = 2; "Mar" = 3; "Abr" = 4; "May" = 5; "Jun" = 6;
    "Jul" = 7; "Ago" = 8; "Sep" = 9; "Oct" = 10; "Nov" = 11; "Dic" = 12
}

# Read the entire file content
$content = Get-Content -Raw $inputFile

# Remove the JSONP callback wrapping to isolate the JSON part.
if ($content -match "^[^(]+\((.*)\);\s*$") {
    $jsonString = $matches[1]
} else {
    Write-Error "Data does not match the expected JSONP format."
    exit
}

# Convert the JSON string to a PowerShell object
$dataObj = $jsonString | ConvertFrom-Json

# Initialize an array to store the parsed objects
$result = @()

# Loop through each entry in the "datos" array
foreach ($item in $dataObj.datos) {
    # Each item is in the format "MMM-YYYY&value"
    $splitData = $item -split "&"
    if ($splitData.Length -eq 2) {
        $datePart = $splitData[0]   # e.g., "Feb-2025"
        $number = $splitData[1]       # e.g., "138.726"

        # Split the date part into month and year
        $dateSplit = $datePart -split "-"
        if ($dateSplit.Length -eq 2) {
            $monthStr = $dateSplit[0]
            $year = [int]$dateSplit[1]

            # Convert month name to number
            if ($monthMap.ContainsKey($monthStr)) {
                $month = $monthMap[$monthStr]

                # Create a custom object with the extracted fields
                $obj = [PSCustomObject]@{
                    Month = $month
                    Year  = $year
                    Value = [decimal]$number
                }
                $result += $obj
            } else {
                Write-Warning "Unknown month: $monthStr"
            }
        }
    }
}

# Convert the resulting array to JSON (with a sufficient depth level)
$jsonOutput = $result | ConvertTo-Json -Depth 3

# Write the JSON output to the output file
Set-Content -Path $outputFile -Value $jsonOutput

Write-Output "Parsed data has been written to $outputFile"
