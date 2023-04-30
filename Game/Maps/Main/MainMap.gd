extends Map

func tick():
	
	match matchTime:
		
		118:
			$Spawners/StrawberryLeft.rpc("spawn")
			$Spawners/StrawberryRight.rpc("spawn")
		108:
			$Spawners/OrangeBottom.rpc("spawn")
			$Spawners/OrangeTop.rpc("spawn")
		90:
			rpc("spawnDots")
		95:
			$Spawners/StrawberryLeft.rpc("spawn")
			$Spawners/StrawberryRight.rpc("spawn")
		75:
			$Spawners/OrangeBottom.rpc("spawn")
			$Spawners/OrangeTop.rpc("spawn")
		60:
			rpc("spawnDots")
		48:
			$Spawners/CherriesBottom.rpc("spawn")
			$Spawners/CherriesTop.rpc("spawn")
		30:
			rpc("spawnDots")
		35:
			$Spawners/StrawberryLeft.rpc("spawn")
			$Spawners/StrawberryRight.rpc("spawn")
		20:
			$Spawners/CherriesBottom.rpc("spawn")
			$Spawners/CherriesTop.rpc("spawn")
	
