/*
 * pvc04v-DC1232-gpio.h - gpio define for DC1232-2ND
 *
 * Copyright (c) 2020 Panasonic Corporation
 * 2020-07-16 Modified
 *
 * This file may be used subject to the terms and conditions of the
 * GNU General Public License Version 2, or any later version
 * at your option, as published by the Free Software Foundation.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */
#define GPIO4	0
#define GPIO5	1
#define GPIO6	2
#define GPIO7	3
#define GPIO8	4
#define GPIO9	5
#define GPIOA	6
#define GPIOB	7
#define GPIOC	8
#define GPIOD	9
#define GPIOE	10
#define GPIOF	11
#define GPIOG	12
#define GPIOH	13
#define GPIOJ	14
#define GPIOK	15
#define GPIOL	16
#define GPIOM	17
#define GPION	18
#define GPIOP	19
#define GPIOR	20
#define GPIOT	20

#define PIN0	0
#define PIN1	1
#define PIN2	2
#define PIN3	3
#define PIN4	4
#define PIN5	5
#define PIN6	6
#define PIN7	7
#define PIN8	8
#define PIN9	9
#define PINA	10
#define PINB	11
#define PINC	12
#define PIND	13
#define PINE	14
#define PINF	15


#define MLB03_PIN(g, p)	(GPIO ##g * 16 + PIN ##p)

