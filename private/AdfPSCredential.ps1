class AdfPSCredential {
    
    # Properties
    [PSCustomObject] $Child
    [String] $Name
    
    # Constructors
    AdfPSCredential ([PSCustomObject] $Child)
    {
        $this.Child = $Child
        $this.Name = $Child.name
    }

}

