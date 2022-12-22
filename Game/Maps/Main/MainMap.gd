extends Map

func tick():
	
	match matchTime:
		
		118:
			$Spawners/StrawberryLeft.rpc("spawn")
			$Spawners/StrawberryRight.rpc("spawn")
		108:
			$Spawners/OrangeBottom.rpc("spawn")
			$Spawners/OrangeTop.rpc("spawn")
		95:
			$Spawners/StrawberryLeft.rpc("spawn")
			$Spawners/StrawberryRight.rpc("spawn")
		75:
			$Spawners/OrangeBottom.rpc("spawn")
			$Spawners/OrangeTop.rpc("spawn")
		48:
			rpc("spawnDots")
			$Spawners/CherriesBottom.rpc("spawn")
			$Spawners/CherriesTop.rpc("spawn")
		35:
			$Spawners/StrawberryLeft.rpc("spawn")
			$Spawners/StrawberryRight.rpc("spawn")
		20:
			$Spawners/CherriesBottom.rpc("spawn")
			$Spawners/CherriesTop.rpc("spawn")
	
