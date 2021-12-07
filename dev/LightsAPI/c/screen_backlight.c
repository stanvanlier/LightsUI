#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <unistd.h>

#define	GPIO_REG_MAP            0xFF634000
#define GPIOX_FSEL_REG_OFFSET   0x116
#define GPIOX_OUTP_REG_OFFSET   0x117
#define GPIOX_INP_REG_OFFSET    0x118
#define BLOCK_SIZE              (4*1024)
#define PIN                     6

static volatile uint32_t *gpio;

void setpinout(){
    int fd;
    if ((fd = open("/dev/gpiomem", O_RDWR | O_SYNC | O_CLOEXEC)) < 0) {
        printf("Unable to open /dev/gpiomem\n");
        //return -1;
    }

    gpio = mmap(0, BLOCK_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, GPIO_REG_MAP);
    if (gpio < 0) {
        printf("Mmap failed.\n");
        //return -1;
    }

    // Print GPIOX FSEL register
    printf("GPIOX_FSEL register : 0x%08x\n",
           *(unsigned int *)(gpio + (GPIOX_FSEL_REG_OFFSET)));

    // Set direction of GPIOX.5 register to out
    *(gpio + (GPIOX_FSEL_REG_OFFSET)) &= ~(1 << PIN);
    printf("GPIOX_FSEL register : 0x%08x\n",
           *(unsigned int *)(gpio + (GPIOX_FSEL_REG_OFFSET)));
}

void __attribute__ ((constructor)) initLibrary(void) {
    setpinout();
}

void screenon(){
    // Set GPIOAO.<PIN> to high
    *(gpio + (GPIOX_OUTP_REG_OFFSET)) |= (1 << PIN);
}
void screenoff(){
    // Set GPIOAO.<PIN> to low
    *(gpio + (GPIOX_OUTP_REG_OFFSET)) &= ~(1 << PIN);
}
