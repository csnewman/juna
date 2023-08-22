package main

import (
	"encoding/binary"
	"fmt"
	"github.com/schollz/progressbar/v3"
	"github.com/spf13/cobra"
	"log"
)

import (
	"os"
)

func main() {
	var device = "/dev/ttyUSB0"

	var rootCmd = &cobra.Command{
		Use: "debugger",
	}

	rootCmd.PersistentFlags().StringVar(&device, "device", device, "device")

	rootCmd.AddCommand(&cobra.Command{
		Use:   "halt",
		Short: "Halt core",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Halting")
			d := Connect(device)
			d.HaltCore()
			fmt.Println("Done")
		},
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "reset",
		Short: "Reset core",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Resetting")
			d := Connect(device)
			d.HaltCore()
			for i := 0; i < 16; i++ {
				d.WriteReg(byte(i), [4]byte{0, 0, 0, 0})
			}
			fmt.Println("Done")
		},
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "resume",
		Short: "Resume core",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Resuming")
			d := Connect(device)
			d.ResumeCore()
			fmt.Println("Done")
		},
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "upload",
		Short: "Upload core",
		Run: func(cmd *cobra.Command, args []string) {
			dat, err := os.ReadFile(args[0])
			if err != nil {
				log.Fatal(err)
			}

			fmt.Println("Uploading")

			d := Connect(device)
			bar := progressbar.DefaultBytes(int64(len(dat)), "uploading")

			for i := 0; i < len(dat); i++ {
				d.WriteMem(i, dat[i])
				bar.Set(i)
			}

			bar.Clear()

			fmt.Println("Done")
		},
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "regs",
		Short: "Print regs",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Regs:")
			d := Connect(device)
			for i := 0; i < 16; i++ {
				v := d.ReadReg(byte(i))
				fmt.Println(" ", i, "\t", v, "\t", binary.LittleEndian.Uint32(v[:]))
			}
			fmt.Println("Done")
		},
	})

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
