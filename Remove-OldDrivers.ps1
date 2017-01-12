<#
    2016.09.01
    перечисляет драйвера в системе
    находит дубликаты в хранилище и удаляет их
    если вам нужно только посмотреть драйвера закомментируйте 135 строку
    если драйвер нужно удалить принудительно используйте pnputil.exe -f -d
#>

#[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("cp866")

#расскомментируйте если вам нужно создать точку восстановления
#Checkpoint-Computer -Description "Driversdelete"

# получаем список драйверов
$temp = dism /online /get-drivers
$Lines = $temp | select -Skip 10

$Operation = "ItIsName"
$Drivers = @()

foreach ( $Line in $Lines ) {

    $temp1 = $Line
    $text = $($temp1.Split( ':' ))[1]

    switch ($Operation) {

        'ItIsName' { $Name = $text
                     $Operation = 'ItIsFileName'
                     break
                   }

        'ItIsFileName' { $FileName = $text.Trim()
                         $Operation = 'ItIsVhod'
                         break
                       }

        'ItIsVhod' { $Vhod = $text.Trim()
                     $Operation = 'ItIsClassName'
                     break
                   }

        'ItIsClassName' { $ClassName = $text.Trim()
                          $Operation = 'ItIsVendor'
                          break
                        }

        'ItIsVendor' { $Vendor = $text.Trim()
                       $Operation = 'ItIsDate'
                       break
                     }

        'ItIsDate' { # переводим дату в европейский стандарт, чтобы сортировать
                     $tmp = $text.split( '.' )
                     $text = "$($tmp[2]).$($tmp[1]).$($tmp[0].Trim())"
                     $Date = $text
                     $Operation = 'ItIsVersion'
                     break
                   }

        'ItIsVersion' { $Version = $text.Trim()
                        $Operation = 'ItIsNull'

                        $params = [ordered]@{ 'FileName' = $FileName
                                              'Vendor' = $Vendor
                                              'Date' = $Date
                                              'Name' = $Name
                                              'ClassName' = $ClassName
                                              'Version' = $Version
                                              'Vhod' = $Vhod
                                            }
    
                        $obj = New-Object -TypeName PSObject -Property $params
                        $Drivers += $obj

                        break
                      }

         'ItIsNull' { $Operation = 'ItIsName'
                      break
                     }

    }
}

Write-Host "все драйверы" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow
$Drivers | sort Filename | ft



Write-Host "несколько версий драйверов" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

$last = ''
$NotUnique = @()

foreach ( $Dr in $($Drivers | sort Filename) ) {
    
    if ($Dr.FileName -eq $last  ) {  $NotUnique += $Dr  }
    $last = $Dr.FileName
}

$NotUnique | sort FileName | ft



Write-Host "устаревшие версии драйверов" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow
$list = $NotUnique | select -ExpandProperty FileName -Unique

$ToDel = @()
foreach ( $Dr in $list ) {
    Write-Host "найден дубликат" -ForegroundColor Yellow
    $sel = $Drivers | where { $_.FileName -eq $Dr } | sort date -Descending | select -Skip 1
    $sel | ft

    $ToDel += $sel
}

Write-Host "драйвера на удаление" -ForegroundColor Green
Write-Host "-------------------" -ForegroundColor Green
Write-Host "будте осторожны, любые автоматические действия опасны" -ForegroundColor Green

$ToDel | ft



# удаляем драйвера
foreach ( $item in $ToDel ) {
    $Name = $($item.Name).Trim()

    Write-Host " " -ForegroundColor Green
    Write-Host "удаляем $Name" -ForegroundColor Green
    Write-Host "pnputil.exe -d $Name" -ForegroundColor Green
    Invoke-Expression -Command "pnputil.exe -d $Name"
}