package main

import (
	"github.com/csnewman/blackice-ii-serialware/client"
	"log"
)

type Device struct {
	client *client.Conn
}

func Connect(device string) *Device {
	c := client.Open(device)

	if s, err := c.Ping(); !s || err != nil {
		log.Fatal("Ping fail", s, err)
	}

	return &Device{
		client: c,
	}
}

func (d *Device) ReadReg(id byte) [4]byte {
	id <<= 1

	if err := d.client.WriteUser([]byte{1, id, 0, 0, 0, 0, 0, 0, 0}, nil); err != nil {
		log.Fatal(err)
	}

	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	return [4]byte(data[0:4])
}

func (d *Device) WriteReg(id byte, value [4]byte) {
	id <<= 1
	id |= 1

	if err := d.client.WriteUser([]byte{1, id, 0, 0, 0, value[0], value[1], value[2], value[3]}, nil); err != nil {
		log.Fatal(err)
	}

	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	if data[0] != 1 {
		log.Fatal("Mismatch", data)
	}
}

func (d *Device) ReadMem(addr int) byte {
	//id <<= 1

	if err := d.client.WriteUser([]byte{2, 0, byte(addr), byte(addr >> 8), byte(addr >> 16), 0, 0, 0, 0}, nil); err != nil {
		log.Fatal(err)
	}

	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	return data[0]

	//log.Println("r", data)

	//return [4]byte(data[0:4])
}

func (d *Device) WriteMem(addr int, value byte) {
	//id <<= 1

	//log.Println("writing")
	if err := d.client.WriteUser([]byte{2, 1, byte(addr), byte(addr >> 8), byte(addr >> 16), 0, 0, 0, value}, nil); err != nil {
		log.Fatal(err)
	}

	//time.Sleep(time.Millisecond * 100)

	//log.Println("waiting")
	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	if data[0] != 123 {
		log.Fatal("Mismatch", data)
	}

	//log.Println("w", data)

	//return [4]byte(data[0:4])
}

func (d *Device) GetCoreState() bool {
	if err := d.client.WriteUser([]byte{3, 0, 0, 0, 0, 0, 0, 0, 0}, nil); err != nil {
		log.Fatal(err)
	}

	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	if data[0] > 1 {
		log.Fatal("Mismatch", data)
	}

	return data[0] == 0
}

func (d *Device) HaltCore() {
	if err := d.client.WriteUser([]byte{3, 1, 0, 0, 0, 0, 0, 0, 0}, nil); err != nil {
		log.Fatal(err)
	}

	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	if data[0] != 1 {
		log.Fatal("Mismatch", data)
	}
}

func (d *Device) ResumeCore() {
	if err := d.client.WriteUser([]byte{3, 2, 0, 0, 0, 0, 0, 0, 0}, nil); err != nil {
		log.Fatal(err)
	}

	data, err := d.client.ReadUser(8, 200, nil)
	if err != nil {
		log.Fatal(err)
	}

	if data[0] != 1 {
		log.Fatal("Mismatch", data)
	}
}
