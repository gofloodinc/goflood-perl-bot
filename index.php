<?php

declare(strict_types=1);

function deepRound(float $number): int
{
    $i = 14;
    do {
        $number = round($number, $i--);
    } while (false !== strpos($number, '.'));
    
    return $number;
}
$number1 = 94.44445;
$number2 = 94.44444;

echo implode(',', [deepRound($number1), round($number1), ceil($number1), number_format($number1)]), PHP_EOL;
echo implode(',', [deepRound($number2), round($number2), ceil($number2), number_format($number2)]), PHP_EOL;
exit;
