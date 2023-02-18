// SPDX-License-Identifier: Unlicensed 

pragma solidity 0.8.17;

/**
 * @title The Dai token contract
 * @author Rohit Goswami
 * @notice DAI contract allows for "unlimited approvals".
 * @custom:experimental This is an experimental contract.
 */
contract Dai {

    /// ward: an address that is allowed to call auth'ed methods.
    mapping (address => uint ) public wards;

    /// @notice allow an address to call auth'ed method
    function rely(address guy) external auth { wards[guy] = 1;}

    /// @notice disallow an address from calling auth'ed methods
    function deny(address guy) external auth {wards[guy] = 0;}

    /// to check whether an address can call this method
    modifier auth {
        require(wards[msg.sender] == 1, "Dai: Not authorized");
        _;
    } 

    /// ERC20 Data
    string public constant name = "Dai Stablecoin";
    string public constant symbol = "DAI"; 
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping( address => uint)) public allowance; 
    mapping (address => uint)                      public nonces;

    /// wad: some quantity of tokens, usually as a fixed point integer with 18 decimal places.
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    /// --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z =x = y) >= x);
    }

    function sub(uint x, uint y) internal pure returns ( uint z) {
        require((z = x - y) <= x);
    }

    /// EIP712 
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Pemit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain((string name, string version, uint256 chainId, address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }

    /// --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    @audit dst : Not checking if dst != address(0) and also check if src and dst is same.`
    function transferFrom(address src, address dst,  uint wad) public returns (bool) {
        require(balanceOf[src] >= wad, "Dai: Insufficient balance");
        if(src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad. "Dai: Insufficient Allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }

        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function mint(address usr, uint wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSuppy = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    @audit here no access control, who can call burn function
    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "Dai: Insufficient balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint(-1)){
            require(allowance[usr][msg.sender] >= wad, "Dai: Insufficient allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }

        balanceOf[usr] = sub(balanceOf[usr] ,wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint wad) extenal returns(bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    /// --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }

    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }

    functiom move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }

    /// --- Approve by signature --- 
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH,
                                holder,
                                spender,
                                expiry,
                                allowed))
        ));

        require(holder != address(0), "Dai: Invalid address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai: Invalid Permit");
        require(expiry == 0 || now <= expiry, "Dai: Permit-expired");
        require(nonce == nonces[holder]++, "Dai: Invalid nonce");
        uint wad = allowed ? uint(-1) : 0;
        alllowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
 
}